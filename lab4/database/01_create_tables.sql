CREATE TABLE members
(
    member_id SERIAL PRIMARY KEY,

    first_name VARCHAR(50) NOT NULL,

    last_name VARCHAR(50) NOT NULL,

    birth_date DATE NOT NULL,

    phone VARCHAR(20) NOT NULL UNIQUE,

    email VARCHAR(100) UNIQUE,

    registration_date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE trainers
(
    trainer_id SERIAL PRIMARY KEY,

    first_name VARCHAR(50) NOT NULL,

    last_name VARCHAR(50) NOT NULL,

    specialization VARCHAR(100) NOT NULL,

    phone VARCHAR(20) NOT NULL UNIQUE,

    salary NUMERIC(10,2) NOT NULL CHECK (salary >= 0)
);

CREATE TABLE memberships
(
    membership_id SERIAL PRIMARY KEY,

    membership_name VARCHAR(100) NOT NULL,

    duration_months INTEGER NOT NULL CHECK (duration_months > 0),

    price NUMERIC(10,2) NOT NULL CHECK (price > 0)
);

CREATE TABLE member_memberships
(
    member_membership_id SERIAL PRIMARY KEY,

    member_id INTEGER NOT NULL,

    membership_id INTEGER NOT NULL,

    start_date DATE NOT NULL,

    end_date DATE NOT NULL,

    FOREIGN KEY (member_id)
        REFERENCES members(member_id)
        ON DELETE CASCADE,

    FOREIGN KEY (membership_id)
        REFERENCES memberships(membership_id)
        ON DELETE CASCADE
);

CREATE TABLE training_sessions
(
    session_id SERIAL PRIMARY KEY,

    trainer_id INTEGER NOT NULL,

    session_name VARCHAR(100) NOT NULL,

    session_date DATE NOT NULL,

    start_time TIME NOT NULL,

    end_time TIME NOT NULL,

    max_participants INTEGER NOT NULL,

    FOREIGN KEY (trainer_id)
        REFERENCES trainers(trainer_id),

    CHECK (max_participants > 0)
);

CREATE TABLE attendance
(
    attendance_id SERIAL PRIMARY KEY,

    member_id INTEGER NOT NULL,

    session_id INTEGER NOT NULL,

    FOREIGN KEY (member_id)
        REFERENCES members(member_id)
        ON DELETE CASCADE,

    FOREIGN KEY (session_id)
        REFERENCES training_sessions(session_id)
        ON DELETE CASCADE
);

CREATE TABLE equipment
(
    equipment_id SERIAL PRIMARY KEY,

    equipment_name VARCHAR(100) NOT NULL,

    quantity INTEGER NOT NULL,

    purchase_date DATE,

    condition VARCHAR(30) DEFAULT 'Good',

    CHECK (quantity >= 0)
);

CREATE INDEX idx_members_phone
ON members(phone);

CREATE INDEX idx_members_email
ON members(email);

CREATE INDEX idx_trainer_specialization
ON trainers(specialization);

CREATE INDEX idx_attendance_member
ON attendance(member_id);

CREATE INDEX idx_attendance_session
ON attendance(session_id);

CREATE INDEX idx_training_trainer
ON training_sessions(trainer_id);