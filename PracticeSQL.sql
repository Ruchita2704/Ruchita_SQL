CREATE TABLE students (
    student_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    date_of_birth DATE,
    gender ENUM('Male', 'Female', 'Other'),
    city VARCHAR(50)
);
INSERT INTO students VALUES
(1, 'Alice Johnson', '2001-03-22', 'Female', 'New York'),
(2, 'Bob Smith', '2000-07-10', 'Male', 'Los Angeles'),
(3, 'Catherine Lee', '2002-12-05', 'Female', 'Chicago'),
(4, 'David Brown', '2001-09-15', 'Male', 'Houston'),
(5, 'Emily Davis', '2003-02-01', 'Female', 'Phoenix'),
(6, 'Frank Wilson', '1999-11-11', 'Male', 'Dallas');
CREATE TABLE enrollments (
    enrollment_id INT PRIMARY KEY,
    student_id INT,
    course_name VARCHAR(100),
    semester VARCHAR(20),
    grade CHAR(1),
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);
INSERT INTO enrollments VALUES
(101, 1, 'Computer Science', 'Spring 2024', 'A'),
(102, 2, 'Mathematics', 'Spring 2024', 'B'),
(103, 1, 'Physics', 'Fall 2024', 'A'),
(104, 3, 'Chemistry', 'Spring 2024', 'C'),
(105, 4, 'Computer Science', 'Spring 2024', 'B'),
(106, 5, 'Mathematics', 'Fall 2024', 'A'),
(107, 2, 'Physics', 'Fall 2024', 'B'),
(108, 6, 'Chemistry', 'Spring 2024', 'A');

SELECT s.full_name, e.course_name, e.semester
FROM students s
JOIN enrollments e ON s.student_id = e.student_id;

SELECT student_id
FROM enrollments
GROUP BY student_id
HAVING COUNT(*) > 1;

SELECT full_name
FROM students
WHERE student_id IN (
    SELECT student_id
    FROM enrollments
    GROUP BY student_id
    HAVING COUNT(*) > 1
);

SELECT course_name, MAX(grade) AS highest_grade
FROM enrollments
GROUP BY course_name;

SELECT city, COUNT(*) AS total_students
FROM students
GROUP BY city;

SELECT s.full_name, COUNT(*) AS course_count
FROM students s
JOIN enrollments e ON s.student_id = e.student_id
GROUP BY s.student_id
HAVING COUNT(*) > 1;

SELECT course_name,
       ROUND(AVG(CASE grade
                    WHEN 'A' THEN 4
                    WHEN 'B' THEN 3
                    WHEN 'C' THEN 2
                    WHEN 'D' THEN 1
                    ELSE 0
                  END), 2) AS avg_grade_point
FROM enrollments
GROUP BY course_name;

SELECT * FROM students
WHERE student_id NOT IN (SELECT student_id FROM enrollments);

SELECT s.full_name
FROM students s
JOIN enrollments e ON s.student_id = e.student_id
GROUP BY s.student_id
HAVING MIN(grade) = 'A' AND MAX(grade) = 'A';

SELECT student_id, full_name, course_name, semester
FROM (
    SELECT s.student_id, s.full_name, e.course_name, e.semester,
           ROW_NUMBER() OVER (PARTITION BY s.student_id ORDER BY e.semester DESC) AS rn
    FROM students s
    JOIN enrollments e ON s.student_id = e.student_id
) AS ranked
WHERE rn = 1;

SELECT course_name, semester, COUNT(*) AS a_count
FROM enrollments
WHERE grade = 'A'
GROUP BY course_name, semester
ORDER BY a_count DESC;

WITH course_counts AS (
  SELECT course_name, COUNT(*) AS total_enrollments
  FROM enrollments
  GROUP BY course_name
)
SELECT * FROM course_counts
ORDER BY total_enrollments DESC
LIMIT 1;

CREATE TABLE student_update_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    old_name VARCHAR(100),
    new_name VARCHAR(100),
    old_city VARCHAR(50),
    new_city VARCHAR(50),
    change_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$

CREATE TRIGGER before_student_update
BEFORE UPDATE ON students
FOR EACH ROW
BEGIN
    IF OLD.full_name != NEW.full_name OR OLD.city != NEW.city THEN
        INSERT INTO student_update_log (
            student_id, old_name, new_name, old_city, new_city
        )
        VALUES (
            OLD.student_id, OLD.full_name, NEW.full_name, OLD.city, NEW.city
        );
    END IF;
END$$

DELIMITER ;

UPDATE students
SET full_name = 'Alice M. Johnson', city = 'Brooklyn'
WHERE student_id = 1;

SELECT * FROM student_update_log;
use chess
SELECT course_name, semester, COUNT(DISTINCT student_id) AS student_count
FROM enrollments
GROUP BY course_name, semester;

DELIMITER $$

CREATE PROCEDURE get_students_with_improved_grades()
BEGIN
    SELECT student_id, full_name, first_grade, last_grade
    FROM (
        SELECT
            s.student_id,
            s.full_name,
            -- First semester grade
            (SELECT e1.grade
             FROM enrollments e1
             WHERE e1.student_id = s.student_id
             ORDER BY e1.semester ASC
             LIMIT 1) AS first_grade,
            -- Last semester grade
            (SELECT e2.grade
             FROM enrollments e2
             WHERE e2.student_id = s.student_id
             ORDER BY e2.semester DESC
             LIMIT 1) AS last_grade
        FROM students s
        WHERE s.student_id IN (SELECT student_id FROM enrollments)
    ) AS grades_compare
    WHERE last_grade < first_grade;  -- 'A' < 'B' in ASCII
END$$

DELIMITER ;

CALL get_students_with_improved_grades();











