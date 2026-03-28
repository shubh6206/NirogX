from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import declarative_base, sessionmaker, relationship
from datetime import datetime

# SQLite database file will be created in your project root
SQLALCHEMY_DATABASE_URL = "sqlite:///./nirogx.db"

# connect_args={"check_same_thread": False} is required for SQLite in FastAPI
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# --- SQLAlchemy ORM Models ---

class DBUser(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)

class DBVital(Base):
    __tablename__ = "vitals"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), default=1) # Defaulting to 1 for testing
    type = Column(String, index=True)
    value = Column(Float)
    unit = Column(String)
    recorded_at = Column(DateTime, index=True)

class DBBloodPressure(Base):
    __tablename__ = "blood_pressure_readings"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), default=1)
    systolic = Column(Float)
    diastolic = Column(Float)
    recorded_at = Column(DateTime, index=True)

class DBSleepSession(Base):
    __tablename__ = "sleep_sessions"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), default=1)
    stage = Column(String)
    duration_minutes = Column(Integer)
    start_time = Column(DateTime, index=True)
    end_time = Column(DateTime)

class DBChatMessage(Base):
    __tablename__ = "chat_messages"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), default=1, index=True)
    session_id = Column(String, index=True) # Groups messages into specific conversations
    role = Column(String) # Will be either "user" or "model"
    text = Column(String)
    timestamp = Column(DateTime, default=datetime.utcnow)

class DBUserGoal(Base):
    __tablename__ = "user_goals"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), default=1, index=True)
    goal_type = Column(String) # e.g., "Water Intake"
    target_value = Column(Float)
    updated_at = Column(DateTime, default=datetime.utcnow)

class DBMedicalHistory(Base):
    __tablename__ = "medical_history"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), default=1, index=True)
    condition = Column(String)
    recorded_at = Column(DateTime, default=datetime.utcnow)
