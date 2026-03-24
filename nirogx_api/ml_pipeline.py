import pandas as pd
from sqlalchemy.orm import Session
from database import DBVital, DBBloodPressure

def generate_user_feature_matrix(db: Session, user_id: int, freq: str = '1H') -> pd.DataFrame:
    """
    Extracts a user's health history and shapes it into a time-series feature matrix.
    
    :param db: SQLAlchemy database session
    :param user_id: The ID of the user to extract
    :param freq: The time bucket frequency ('1H' for hourly, '1D' for daily)
    :return: A clean Pandas DataFrame ready for ML inference
    """
    
    # 1. Extract Vitals using pandas read_sql for blazing fast conversion
    vitals_query = db.query(
        DBVital.recorded_at, 
        DBVital.type, 
        DBVital.value
    ).filter(DBVital.user_id == user_id)
    
    df_vitals = pd.read_sql(vitals_query.statement, db.bind)
    
    if df_vitals.empty:
        return pd.DataFrame() # Return empty if no data exists

    # 2. Pivot the data: Turn 'type' rows into their own feature columns
    # This turns a vertical table into a horizontal matrix
    df_pivoted = df_vitals.pivot_table(
        index='recorded_at', 
        columns='type', 
        values='value',
        aggfunc='mean' # If multiple readings exist in the exact same second, average them
    )
    
    # 3. Time-Series Resampling (The most important step for ML)
    # Algorithms need uniform time steps. This groups data into buckets (e.g., Hourly)
    df_resampled = df_pivoted.resample(freq).mean()
    
    # 4. Handle Missing Data (Imputation)
    # If a user didn't sync heart rate for an hour, we shouldn't feed 'NaN' to the AI.
    # .interpolate(method='time') guesses the missing values based on surrounding data.
    # .ffill() carries the last known value forward if interpolation isn't possible.
    df_clean = df_resampled.interpolate(method='time').ffill().bfill()
    
    # Optional: Merge Blood Pressure data if needed
    bp_query = db.query(
        DBBloodPressure.recorded_at, 
        DBBloodPressure.systolic, 
        DBBloodPressure.diastolic
    ).filter(DBBloodPressure.user_id == user_id)
    
    df_bp = pd.read_sql(bp_query.statement, db.bind)
    
    if not df_bp.empty:
        # Group BP by the exact same frequency and merge it into our main matrix
        df_bp.set_index('recorded_at', inplace=True)
        df_bp_resampled = df_bp.resample(freq).mean().interpolate(method='time').ffill().bfill()
        df_clean = df_clean.join(df_bp_resampled, how='outer')
        # One final fill just in case the outer join introduced new NaNs at the edges
        df_clean = df_clean.ffill().bfill()

    return df_clean
