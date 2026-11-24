CREATE TABLE users
(
    user_id SERIAL PRIMARY KEY,

    username VARCHAR(50) NOT NULL UNIQUE,

    password_hash VARCHAR(255) NOT NULL,

    email VARCHAR(100) NOT NULL UNIQUE,

    role VARCHAR(20) NOT NULL DEFAULT 'user',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



INSERT INTO users
(
    username,
    password_hash,
    email,
    role
)
VALUES
(
    'admin',
    'admin123',
    'admin@sportsclub.com',
    'admin'
);



INSERT INTO users
(
    username,
    password_hash,
    email,
    role
)
VALUES
(
    'trainer',
    'trainer123',
    'trainer@sportsclub.com',
    'trainer'
);



INSERT INTO users
(
    username,
    password_hash,
    email,
    role
)
VALUES
(
    'member',
    'member123',
    'member@sportsclub.com',
    'user'
);