-- ============================================================================
-- MASTER ONBOARDING SCRIPT: FORCE DISCONNECT + DROP + CREATE
-- ============================================================================
-- IMPORTANT: Always run from the 'postgres' superuser database.
--            \c postgres below ensures this even if you're connected elsewhere.
-- ============================================================================
\c postgres

-- 1. DATABASE: talk_2data_employee_rdb
-- ----------------------------------------------------------------------------
SELECT pg_terminate_backend(pid) FROM pg_stat_activity
WHERE datname = 'talk_2data_employee_rdb' AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS talk_2data_employee_rdb WITH (FORCE);
CREATE DATABASE talk_2data_employee_rdb;
\c talk_2data_employee_rdb;

DROP TABLE IF EXISTS assignments, salaries, employees, projects, departments CASCADE;

CREATE TABLE departments (id SERIAL PRIMARY KEY, dept_name VARCHAR(100), location VARCHAR(100));
CREATE TABLE employees (id SERIAL PRIMARY KEY, name VARCHAR(100), email VARCHAR(100), dept_id INT REFERENCES departments(id));
CREATE TABLE projects (id SERIAL PRIMARY KEY, project_name VARCHAR(100), budget NUMERIC);
CREATE TABLE assignments (employee_id INT REFERENCES employees(id), project_id INT REFERENCES projects(id), role_assigned VARCHAR(50), PRIMARY KEY (employee_id, project_id));
CREATE TABLE salaries (id SERIAL PRIMARY KEY, employee_id INT REFERENCES employees(id), amount NUMERIC, payment_date DATE);

COMMENT ON TABLE departments IS 'Organizational units within the company';
COMMENT ON TABLE employees IS 'Full profile of staff members including contact details and department mapping';
COMMENT ON TABLE projects IS 'List of company initiatives with associated financial budgets';
COMMENT ON TABLE assignments IS 'Link table connecting employees to specific projects and their specific roles';
COMMENT ON TABLE salaries IS 'Historical payroll records tracking payments made to employees';
COMMENT ON COLUMN assignments.role_assigned IS 'The specific job title or function the employee performed for a specific project';
COMMENT ON COLUMN salaries.amount IS 'The gross amount paid to the employee for the specified payment date';

INSERT INTO departments (dept_name, location) VALUES ('Engineering', 'NY'), ('Marketing', 'LDN'), ('Sales', 'SF'), ('HR', 'BER'), ('Finance', 'TKY');
INSERT INTO employees (name, email, dept_id) SELECT 'Employee_' || i, 'user' || i || '@test.com', (floor(random() * 5) + 1)::int FROM generate_series(1, 100) s(i);
INSERT INTO projects (project_name, budget) SELECT 'Project_' || i, (random() * 100000)::numeric FROM generate_series(1, 10) s(i);
INSERT INTO assignments (employee_id, project_id, role_assigned) SELECT (floor(random() * 100) + 1)::int, (floor(random() * 10) + 1)::int, 'Contributor' FROM generate_series(1, 150) s(i) ON CONFLICT DO NOTHING;
INSERT INTO salaries (employee_id, amount, payment_date) SELECT e.id, (4000 + random() * 5000)::numeric, d.d_date FROM employees e CROSS JOIN (SELECT '2026-01-15'::date AS d_date UNION SELECT '2026-02-15'::date UNION SELECT '2026-03-15'::date) d;


-- 2. DATABASE: talk2data_aviation_rdb
-- ----------------------------------------------------------------------------
\c postgres
SELECT pg_terminate_backend(pid) FROM pg_stat_activity 
WHERE datname = 'talk2data_aviation_rdb' AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS talk2data_aviation_rdb WITH (FORCE);
CREATE DATABASE talk2data_aviation_rdb;
\c talk2data_aviation_rdb;

DROP TABLE IF EXISTS tickets, flights, aircraft, passengers CASCADE;

CREATE TABLE aircraft (id SERIAL PRIMARY KEY, model VARCHAR(50), total_seats INT);
CREATE TABLE flights (id SERIAL PRIMARY KEY, flight_number VARCHAR(10), origin CHAR(3), destination CHAR(3), departure_time TIMESTAMP, aircraft_id INT REFERENCES aircraft(id));
CREATE TABLE passengers (id SERIAL PRIMARY KEY, full_name VARCHAR(100), passport_number VARCHAR(20) UNIQUE, loyalty_tier VARCHAR(20));
CREATE TABLE tickets (id SERIAL PRIMARY KEY, flight_id INT REFERENCES flights(id), passenger_id INT REFERENCES passengers(id), seat_number VARCHAR(5), price NUMERIC(10, 2));

COMMENT ON TABLE aircraft IS 'Physical airplane assets owned or operated by the airline';
COMMENT ON TABLE flights IS 'Scheduled flight routes connecting origins and destinations with specific aircraft';
COMMENT ON TABLE passengers IS 'Personal information and loyalty status of customers';
COMMENT ON TABLE tickets IS 'Financial and seating record for a specific passenger on a specific flight';
COMMENT ON COLUMN aircraft.total_seats IS 'The maximum passenger capacity of the airplane model';
COMMENT ON COLUMN flights.origin IS '3-letter IATA airport code for the starting location (e.g., JFK)';
COMMENT ON COLUMN flights.destination IS '3-letter IATA airport code for the arrival location (e.g., LHR)';
COMMENT ON COLUMN passengers.loyalty_tier IS 'Customer status levels: Bronze, Silver, Gold, or Platinum';
COMMENT ON COLUMN tickets.price IS 'The total cost paid for the flight ticket in USD';

INSERT INTO aircraft (model, total_seats) VALUES ('Boeing 737', 180), ('Airbus A320', 150), ('Boeing 787', 250), ('Embraer E190', 100);
INSERT INTO flights (flight_number, origin, destination, departure_time, aircraft_id) SELECT 'FL' || (100 + i), (ARRAY['JFK', 'LHR', 'SFO', 'DXB', 'HND'])[floor(random() * 5 + 1)], (ARRAY['CDG', 'SIN', 'LAX', 'SYD', 'FRA'])[floor(random() * 5 + 1)], NOW() + (i || ' hours')::interval, (floor(random() * 4) + 1)::int FROM generate_series(1, 20) s(i);
INSERT INTO passengers (full_name, passport_number, loyalty_tier) SELECT 'Passenger_' || i, 'PASS' || (1000 + i), (ARRAY['Bronze', 'Silver', 'Gold', 'Platinum'])[floor(random() * 4 + 1)] FROM generate_series(1, 100) s(i);
INSERT INTO tickets (flight_id, passenger_id, seat_number, price) SELECT (floor(random() * 20) + 1)::int, s.i, (floor(random() * 30) + 1) || (ARRAY['A', 'B', 'C', 'D'])[floor(random() * 4 + 1)], (200 + random() * 800)::numeric FROM generate_series(1, 100) s(i);


-- 3. DATABASE: talk_2data_healthcare_rdb
-- ----------------------------------------------------------------------------
\c postgres
SELECT pg_terminate_backend(pid) FROM pg_stat_activity 
WHERE datname = 'talk_2data_healthcare_rdb' AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS talk_2data_healthcare_rdb WITH (FORCE);
CREATE DATABASE talk_2data_healthcare_rdb;
\c talk_2data_healthcare_rdb;

DROP TABLE IF EXISTS medical_records, appointments, doctors, patients CASCADE;

CREATE TABLE patients (id SERIAL PRIMARY KEY, first_name VARCHAR(50), last_name VARCHAR(50), dob DATE, gender CHAR(1));
CREATE TABLE doctors (id SERIAL PRIMARY KEY, doctor_name VARCHAR(100), specialization VARCHAR(100), years_experience INT);
CREATE TABLE appointments (id SERIAL PRIMARY KEY, patient_id INT REFERENCES patients(id), doctor_id INT REFERENCES doctors(id), appointment_date DATE, status VARCHAR(20));
CREATE TABLE medical_records (id SERIAL PRIMARY KEY, patient_id INT REFERENCES patients(id), diagnosis TEXT, prescription TEXT, visit_date DATE);

COMMENT ON TABLE patients IS 'Sensitive demographic data and identification for hospital visitors';
COMMENT ON TABLE doctors IS 'Medical professionals, their specialties, and tenure';
COMMENT ON TABLE appointments IS 'Scheduled meetings between patients and doctors';
COMMENT ON TABLE medical_records IS 'Clinical history including diagnoses and prescribed treatments for patients';
COMMENT ON COLUMN doctors.specialization IS 'The specific field of medicine the doctor is qualified in (e.g., Cardiology)';
COMMENT ON COLUMN appointments.status IS 'Current state of the visit: Scheduled, Completed, or Cancelled';
COMMENT ON COLUMN medical_records.diagnosis IS 'Professional medical determination of the patients condition';
COMMENT ON COLUMN medical_records.prescription IS 'Detailed list of medications or treatments advised by the doctor';

INSERT INTO doctors (doctor_name, specialization, years_experience) VALUES ('Dr. Smith', 'Cardiology', 15), ('Dr. Jones', 'Neurology', 10), ('Dr. Wong', 'Pediatrics', 8), ('Dr. Garcia', 'Orthopedics', 20);
INSERT INTO patients (first_name, last_name, dob, gender) SELECT 'First_' || i, 'Last_' || i, '1960-01-01'::date + (random() * 20000)::int * '1 day'::interval, (ARRAY['M', 'F'])[floor(random() * 2 + 1)] FROM generate_series(1, 100) s(i);
INSERT INTO appointments (patient_id, doctor_id, appointment_date, status) SELECT s.i, (floor(random() * 4) + 1)::int, CURRENT_DATE + (floor(random() * 30))::int, 'Scheduled' FROM generate_series(1, 100) s(i);
INSERT INTO medical_records (patient_id, diagnosis, prescription, visit_date) SELECT (floor(random() * 100) + 1)::int, 'Diagnosis Code ' || (floor(random() * 500)), 'Medication_' || (floor(random() * 10)), CURRENT_DATE - (floor(random() * 365))::int FROM generate_series(1, 100) s(i);


-- 4. DATABASE: talk_2data_telcom_rdb
-- ----------------------------------------------------------------------------
\c postgres
SELECT pg_terminate_backend(pid) FROM pg_stat_activity 
WHERE datname = 'talk_2data_telcom_rdb' AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS talk_2data_telcom_rdb WITH (FORCE);
CREATE DATABASE talk_2data_telcom_rdb;
\c talk_2data_telcom_rdb;

DROP TABLE IF EXISTS call_logs, subscriptions, plans, customers CASCADE;

CREATE TABLE customers (id SERIAL PRIMARY KEY, customer_name VARCHAR(100), phone_number VARCHAR(15) UNIQUE, city VARCHAR(50));
CREATE TABLE plans (id SERIAL PRIMARY KEY, plan_name VARCHAR(50), monthly_cost NUMERIC(10, 2), data_limit_gb INT);
CREATE TABLE subscriptions (id SERIAL PRIMARY KEY, customer_id INT REFERENCES customers(id), plan_id INT REFERENCES plans(id), start_date DATE);
CREATE TABLE call_logs (id SERIAL PRIMARY KEY, customer_id INT REFERENCES customers(id), receiver_number VARCHAR(15), duration_minutes INT, call_timestamp TIMESTAMP);

COMMENT ON TABLE customers IS 'Registry of mobile subscribers and their primary contact locations';
COMMENT ON TABLE plans IS 'Available service packages with data caps and monthly pricing';
COMMENT ON TABLE subscriptions IS 'Mapping of which customers are currently enrolled in which service plans';
COMMENT ON TABLE call_logs IS 'Transaction records of every call made, used for usage-based billing';
COMMENT ON COLUMN plans.data_limit_gb IS 'The monthly data allowance before speeds are throttled';
COMMENT ON COLUMN call_logs.duration_minutes IS 'Length of the phone call in minutes; vital for calculating extra charges';
COMMENT ON COLUMN call_logs.receiver_number IS 'The external phone number that the subscriber called';

INSERT INTO plans (plan_name, monthly_cost, data_limit_gb) VALUES ('Basic', 20.00, 5), ('Premium', 50.00, 50), ('Unlimited', 80.00, 500);
INSERT INTO customers (customer_name, phone_number, city) SELECT 'Customer_' || i, '555-' || LPAD(i::text, 4, '0'), (ARRAY['New York', 'Chicago', 'Austin', 'Seattle'])[floor(random() * 4 + 1)] FROM generate_series(1, 100) s(i);
INSERT INTO subscriptions (customer_id, plan_id, start_date) SELECT s.i, (floor(random() * 3) + 1)::int, '2025-01-01'::date + (i % 30) FROM generate_series(1, 100) s(i);
INSERT INTO call_logs (customer_id, receiver_number, duration_minutes, call_timestamp) SELECT (floor(random() * 100) + 1)::int, '555-' || LPAD((floor(random() * 9000) + 1000)::text, 4, '0'), (floor(random() * 45) + 1)::int, NOW() - (random() * '30 days'::interval) FROM generate_series(1, 150) s(i);

-- Final cleanup: Return to postgres master
\c postgres
SELECT 'ALL DATABASES RE-CREATED AND POPULATED SUCCESSFULLY!' AS status;