DROP TABLE IF EXISTS registrations;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS members;

CREATE TABLE members (
    id        SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email     VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE courses (
    id    SERIAL PRIMARY KEY,
    title VARCHAR(150) NOT NULL UNIQUE
);

CREATE TABLE registrations (
    id         SERIAL PRIMARY KEY,
    member_id  INT NOT NULL REFERENCES members(id),
    course_id  INT NOT NULL REFERENCES courses(id),
    UNIQUE (member_id, course_id)
);

INSERT INTO members (full_name, email) VALUES
 ('Nguyễn An', 'an@example.com'),
 ('Lê Chi',    'chi@example.com'),
 ('Trần Bình', 'binh@example.com'),
 ('Phạm Dung', 'dung@example.com');

INSERT INTO courses (title) VALUES
 ('Lập trình Web'),
 ('Cơ sở dữ liệu'),
 ('Mạng máy tính'),
 ('Trí tuệ nhân tạo');

INSERT INTO registrations (member_id, course_id) VALUES
 (1, 1), (1, 2), (1, 3),
 (2, 1),
 (3, 1), (3, 2);
