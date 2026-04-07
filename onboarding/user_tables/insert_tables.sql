-- Insert 5 Departments
INSERT INTO departments (dept_name, location) VALUES 
('Engineering', 'New York'), ('Marketing', 'London'), 
('Sales', 'San Francisco'), ('HR', 'Berlin'), ('Finance', 'Tokyo');

-- Insert 100 Employees
INSERT INTO employees (name, email, dept_id)
SELECT 
    'Employee_' || i, 
    'user' || i || '@company.com', 
    (floor(random() * 5) + 1)::int
FROM generate_series(1, 100) s(i);

-- Insert 10 Projects
INSERT INTO projects (project_name, budget)
SELECT 
    'Project_' || i, 
    (random() * 500000 + 50000)::numeric(12,2)
FROM generate_series(1, 10) s(i);

-- Insert 150 Assignments (M2M linkages)
INSERT INTO assignments (employee_id, project_id, role_assigned)
SELECT 
    (floor(random() * 100) + 1)::int, 
    (floor(random() * 10) + 1)::int,
    (ARRAY['Lead', 'Developer', 'Designer', 'QA', 'Manager'])[floor(random() * 5) + 1]
FROM generate_series(1, 150) s(i)
ON CONFLICT DO NOTHING; -- Avoid duplicates in junction table

-- Insert Salary records for Jan, Feb, and March
-- Each employee gets 3 months of salary data
INSERT INTO salaries (employee_id, amount, payment_date)
SELECT 
    e.id, 
    (4000 + random() * 6000)::numeric(10,2), 
    d.d_date
FROM employees e
CROSS JOIN (
    SELECT '2026-01-15'::date AS d_date
    UNION SELECT '2026-02-15'::date
    UNION SELECT '2026-03-15'::date
) d;

SELECT * FROM EMPLOYEES;-- 1. Clear existing data to reset IDs
