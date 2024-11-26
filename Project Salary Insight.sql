
CREATE TABLE Departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(50)
);

CREATE TABLE Employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department_id INT,
    salary DECIMAL(10, 2),
    FOREIGN KEY (department_id) REFERENCES Departments(department_id)
);

CREATE TABLE Projects (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(50),
    budget DECIMAL(10, 2)
);

CREATE TABLE EmployeeProjects (
    employee_id INT,
    project_id INT,
    PRIMARY KEY (employee_id, project_id),
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id),
    FOREIGN KEY (project_id) REFERENCES Projects(project_id)
);

INSERT INTO Departments (department_id, department_name) VALUES
(1, 'HR'),
(2, 'IT'),
(3, 'Sales');


INSERT INTO Employees (employee_id, first_name, last_name, department_id, salary) VALUES
(1, 'John', 'Doe', 1, 60000),
(2, 'Jane', 'Smith', 1, 70000),
(3, 'Jim', 'Brown', 2, 80000),
(4, 'Jake', 'White', 2, 90000),
(5, 'Jill', 'Black', 3, 50000),
(6, 'Joe', 'Green', 3, 75000),
(7, 'Jodie', 'Blue', 1, 95000),
(8, 'Jack', 'Gray', 2, 65000);

-- Insert sample data into Projects
INSERT INTO Projects (project_id, project_name, budget) VALUES
(1, 'Project A', 100000),
(2, 'Project B', 150000),
(3, 'Project C', 200000),
(4, 'Project D', 50000),
(5, 'Project E', 300000);


INSERT INTO EmployeeProjects (employee_id, project_id) VALUES
(1, 1),
(2, 1),
(3, 2),
(4, 3),
(5, 3),
(6, 4),
(7, 5),
(8, 2);


/*1. Find all employees who earn more than the average salary of employees in their own department and who also work on at least two different projects*/

SELECT *
FROM Employees emp
JOIN (
    SELECT department_id, AVG(salary) avg_salary
    FROM Employees
    GROUP BY department_id
) avs ON emp.department_id = avs.department_id
JOIN (
    SELECT employee_id, COUNT(project_id) count_pro 
    FROM EmployeeProjects 
    GROUP BY employee_id 
    HAVING COUNT(project_id)>=2
    ) emppro on emp.employee_id = emppro.employee_id
WHERE salary > avs.avg_salary;

/*2. List departments where the total salary of employees is greater than the average salary of all employees, and at least one employee in that department earns more than $80,000*/

SELECT SUM(emp.salary) sum_salary, AVG(emp.salary) avg_salary, emp.department_id, dep.department_name 
FROM Employees emp
JOIN Departments dep ON emp.department_id = dep.department_id
GROUP BY emp.department_id
HAVING SUM(emp.salary) > AVG(emp.salary) ;

/*3. Find projects where the budget is greater than the average budget of all projects associated with employees earning less than the minimum salary in the IT department*/

WITH AVG_budget AS (
    SELECT AVG(budget) avg_budget
    FROM Projects pro
    JOIN EmployeeProjects emppro ON pro.project_id = emppro.project_id
    JOIN Employees emp ON emppro.employee_id = emp.employee_id
    WHERE emp.salary < (SELECT MIN(salary) FROM Employees WHERE department_id = 2)
)
SELECT *
FROM Projects 
WHERE budget > (SELECT avg_budget FROM AVG_budget);

/*4. Get the names of employees who work on projects with a budget greater than the highest budget project assigned to employees in the HR department*/

WITH MaxBudget_HR as (
    SELECT MAX(budget) max_budget
    FROM Projects pro
    JOIN EmployeeProjects emppro on pro.project_id = emppro.project_id
    JOIN Employees emp on emppro.employee_id = emp.employee_id
    WHERE department_id = 1
),
Project_high as (
    SELECT project_id
    FROM Projects
    WHERE budget > (SELECT max_budget FROM MaxBudget_HR)
)
SELECT emp.first_name, emp.last_name
FROM Employees emp
JOIN EmployeeProjects emppro on emp.employee_id = emppro.employee_id
JOIN Project_high pro on emppro.project_id = pro.project_id; 

/*5. List the departments where every employee earns less than the highest salary in the Sales department*/

WITH Maxsalary_Sales as (
    SELECT MAX(salary) max_salary
    FROM Employees
    WHERE department_id = 3
    )

SELECT dep.department_name
FROM Departments dep
JOIN Employees emp on dep.department_id = emp.department_id
GROUP BY department_name
HAVING MAX(emp.salary) < (SELECT max_salary FROM Maxsalary_Sales);

/*6. Find all employees whose salary is greater than the salary of any employee in the same department who is assigned to the same project.*/
WITH Same_project AS (
    SELECT emp1.employee_id, emp1.salary AS my_salary, emp2.salary AS colleague_salary
    FROM Employees emp1
    JOIN EmployeeProjects emppro1 ON emp1.employee_id = emppro1.employee_id
    JOIN EmployeeProjects emppro2 ON emppro1.project_id = emppro2.project_id
    JOIN Employees emp2 ON emppro2.employee_id = emp2.employee_id
    WHERE emp1.employee_id != emp2.employee_id
)
SELECT first_name, last_name, salary
FROM Employees
WHERE salary > ANY (SELECT colleague_salary FROM Same_project);

/*7. Get departments where the average salary of employees is less than the maximum salary of employees in the HR department*/

WITH max_salary_hr as (
    SELECT MAX(salary) max_hr
    FROM Employees
    WHERE department_id = 1
),
Avg_salary_dep as (
    SELECT AVG(salary) avg_salary, department_id
    FROM Employees
    GROUP BY department_id
)

SELECT dep.department_id, dep.department_name
FROM Departments dep
JOIN Avg_salary_dep avg_dep ON dep.department_id = avg_dep.department_id
WHERE avg_dep.avg_salary < (SELECT max_hr FROM max_salary_hr );

/*8. Find employees who work on all projects that have a budget lower than $150,000 and also earn more than the average salary of all employees in their department*/

WITH avg_Salary as (
    SELECT AVG(salary) avg_salary, department_id
    FROM Employees
    GROUP BY department_id
),
projects_lowb as (
    SELECT *
    FROM Projects
    WHERE budget < 150000
    
)

SELECT emp.first_name, emp.last_name
FROM Employees emp
JOIN EmployeeProjects emppro on emp.employee_id = emppro.employee_id
JOIN projects_lowb plb on emppro.project_id = plb.project_id
JOIN avg_Salary avs on emp.department_id = avs.department_id
WHERE emp.salary > avs.avg_salary;

/*9. List all employees who are assigned to projects that do not have a budget greater than the average project budget.*/

SELECT emp.first_name, emp.last_name
FROM Employees emp
JOIN EmployeeProjects emppro ON emp.employee_id = emppro.employee_id
JOIN Projects pro ON emppro.project_id = pro.project_id
WHERE pro.budget < (SELECT AVG(budget) avg_budget FROM Projects);

/*10. Find the names of employees who earn more than the average salary of employees in their own department but are not working on any projects with budgets above the average project budget.*/

WITH emp_budget_low as (
    SELECT emp.*
    FROM Employees emp
    JOIN EmployeeProjects emppro ON emp.employee_id = emppro.employee_id
    JOIN Projects pro on emppro.project_id = pro.project_id
    WHERE pro.budget < (SELECT AVG(budget) avg_budget FROM Projects)
),
avg_salary as ( 
    SELECT AVG(salary) avg_sal, department_id
    FROM Employees
    GROUP BY department_id
)
SELECT emp.first_name, emp.last_name
FROM Employees emp
JOIN avg_salary ON emp.department_id = avg_salary.department_id
JOIN emp_budget_low ON emp.employee_id = emp_budget_low.employee_id
WHERE emp.salary < avg_salary.avg_sal;


/*11. Get all employees who are the highest-paid in their department and work on at least one project that has a budget greater than $200,000.*/

WITH Count_project as (
    SELECT COUNT(pro.project_id) count_pro, emppro.employee_id
    FROM Projects pro
    JOIN EmployeeProjects emppro ON pro.project_id = emppro.project_id
    WHERE pro.budget > 200000
    GROUP BY employee_id
    HAVING COUNT(pro.project_id)>= 1
),
    Max_salary as (
    SELECT MAX(salary) max_salary, department_id
    FROM Employees 
    GROUP BY department_id
    )

SELECT emp.first_name, emp.last_name, emp.salary
FROM Employees emp
JOIN Max_salary ms ON emp.department_id = ms.department_id
JOIN Count_project cp ON emp.employee_id = cp.employee_id
WHERE emp.salary = ms.max_salary;

/*12. Find departments where the total number of employees salary exceeds the total budget of all projects associated with that department.*/

WITH sum_emp_salary as (
    SELECT SUM(salary) sum_salary, department_id
    FROM Employees 
    GROUP BY department_id
),
sum_budget as (
    SELECT  SUM(pro.budget) sum_budget, emp.department_id
    FROM Projects pro
    JOIN EmployeeProjects emppro ON pro.project_id = emppro.project_id
    JOIN Employees emp ON  emppro.employee_id = emp.employee_id
    GROUP BY emp.department_id
)

SELECT dep.department_id, dep.department_name
FROM Departments dep 
JOIN sum_emp_salary ses ON dep.department_id = ses.department_id
JOIN sum_budget sb ON dep.department_id = sb.department_id
WHERE ses.sum_salary > sb.sum_budget;

/*13. List all employees who are assigned to projects that have budgets higher than the average budget of all projects in the IT department*/

WITH avg_budget_it as (
    SELECT AVG(pro.budget) avg_budget
    FROM Projects pro
    JOIN EmployeeProjects emppro ON pro.project_id = emppro.project_id
    JOIN Employees emp ON emppro.employee_id = emp.employee_id
    WHERE emp.department_id =2
)

SELECT emp.first_name, emp.last_name
FROM Employees emp
JOIN EmployeeProjects emppro ON emp.employee_id = emppro.employee_id
JOIN Projects pro ON emppro.project_id = pro.project_id
WHERE pro.budget > (SELECT avg_budget FROM avg_budget_it);

/*14.Find all projects that are assigned to employees earning less than the average salary of all employees, but have budgets greater than $100,000.*/

WITH emp_ls as (
    SELECT emppro.project_id
    FROM EmployeeProjects emppro
    JOIN Employees emp on emppro.employee_id = emp.employee_id
    WHERE emp.salary < (SELECT AVG(salary) avg_salary FROM Employees)
)
SELECT pro.*
FROM Projects pro
JOIN emp_ls el ON pro.project_id = el.project_id
WHERE pro.budget > 100000; 

/*15.Identify employees who earn more than any employee in the Sales department but work in a different department*/

WITH max_salary_sales as (
    SELECT MAX(salary) max_salary
    FROM Employees
    WHERE department_id = 3
)

SELECT employee_id, first_name, last_name
FROM Employees
WHERE salary > (SELECT max_salary FROM max_salary_sales) AND department_id != 3; 

/*16.Get the departments that have at least one employee earning less than the average salary of that department.*/

WITH count_ls as (
    SELECT COUNT(employee_id) cemp, AVG(salary) avg_salary, department_id
    FROM Employees
    GROUP BY department_id
)

SELECT distinct dep.department_name
FROM Departments dep
JOIN Employees emp ON dep.department_id = emp.department_id
JOIN count_ls cl ON dep.department_id = cl.department_id
WHERE cl.cemp > 1 and emp.salary < cl.avg_salary; 

/*18.Find projects that do not have any employees earning a salary greater than $80,000 assigned to them.*/

WITH project_highs as (
    SELECT pro.project_id
    FROM Projects pro
    JOIN EmployeeProjects emppro ON pro.project_id = emppro.project_id
    JOIN Employees emp ON emppro.employee_id = emp.employee_id
    WHERE emp.salary > 80000
)

SELECT distinct pro.project_id, pro.project_name
FROM Projects pro
JOIN EmployeeProjects emppro ON pro.project_id = emppro.project_id
JOIN Employees emp ON emppro.employee_id = emp.employee_id
WHERE pro.project_id NOT IN (SELECT project_id FROM project_highs ); 

/*19.List employees who are not assigned to any projects with a budget less than $50,000*/

WITH empl_bl as (
    SELECT emp.employee_id
    FROM Employees emp
    JOIN EmployeeProjects emppro ON emp.employee_id = emppro.employee_id
    JOIN Projects pro ON emppro.project_id = pro.project_id
    WHERE pro.budget < 50000
)
SELECT emp.employee_id, emp.first_name, emp.last_name
FROM Employees emp
JOIN EmployeeProjects emppro ON emp.employee_id = emppro.employee_id
JOIN Projects pro ON emppro.project_id = pro.project_id
WHERE pro.budget NOT IN (SELECT employee_id FROM empl_bl ); 

/*20.Find all employees who work on projects that exceed the average project budget but earn less than the highest salary in the IT department.*/

WITH high_pro_budget as (
    SELECT emp.employee_id
    FROM Employees emp
    JOIN EmployeeProjects emppro ON emp.employee_id = emppro.employee_id
    JOIN Projects pro ON emppro.project_id = pro.project_id
    WHERE pro.budget > (SELECT AVG(budget) FROM Projects)
)

SELECT emp.first_name, emp.last_name
FROM Employees emp
JOIN high_pro_budget hpb ON emp.employee_id = hpb.employee_id
WHERE emp.salary < (SELECT MAX(salary) max_salary FROM Employees WHERE department_id = 2);

/*21.List departments where the number of projects exceeds the number of employees in that department.*/

WITH count_empl as (
    SELECT COUNT(employee_id) count_em, department_id
    FROM Employees
    GROUP BY department_id
),
count_pro_dep as (
    SELECT COUNT(pro.project_id) count_p, emp.department_id
    FROM Projects pro
    JOIN EmployeeProjects emppro ON pro.project_id = emppro.project_id
    JOIN Employees emp ON emppro.employee_id = emp.employee_id
    GROUP BY emp.department_id
)

SELECT dep.department_name
FROM Departments dep
JOIN count_pro_dep cpd ON dep.department_id = cpd.department_id
JOIN count_empl ce ON dep.department_id = ce.department_id
WHERE cpd.count_p > ce.count_em;

/*22.Get the names of employees who earn less than the lowest salary in the HR department but work on any project.*/

WITH low_salary_hr as (
    SELECT MIN(salary) min_salary
    FROM Employees 
    WHERE department_id = 1
)

SELECT emp.employee_id, emp.first_name, emp.last_name
FROM Employees emp
JOIN EmployeeProjects emppro ON emp.employee_id = emppro.employee_id
WHERE emp.salary < (SELECT min_salary FROM low_salary_hr); 

/*23. Find all employees who are the only ones in their department working on projects with budgets exceeding $100,000.*/

WITH emp_budget_high as (
    SELECT emp.employee_id, emp.department_id, pro.project_id
    FROM Employees emp
    JOIN EmployeeProjects emppro ON emp.employee_id = emppro.employee_id
    JOIN Projects pro ON emppro.project_id = pro.project_id
    WHERE pro.budget > 100000
),
count_employees as (
    SELECT COUNT(emp.employee_id) count_emp, emp.department_id
    FROM Employees emp
    JOIN emp_budget_high ebh ON emp.employee_id = ebh.employee_id
    GROUP BY emp.department_id
)
    SELECT emp.employee_id, emp.first_name, emp.last_name
    FROM Employees emp
    JOIN emp_budget_high ebh ON emp.employee_id = ebh.employee_id
    JOIN count_employees ce ON emp.department_id = ce.department_id
    WHERE ce.count_emp = 1; 

/*24. Find departments where at least one employee earns less than the department's average salary and is working on a project with a budget over $200,000.*/

WITH emp_budget_high as (
    SELECT emp.employee_id, emp.department_id, pro.project_id
    FROM Employees emp
    JOIN EmployeeProjects ep on emp.employee_id = ep.employee_id
    JOIN Projects pro on ep.project_id = pro.project_id
    WHERE pro.budget > 200000 
), 
emp_sal_high as (
    SELECT AVG(salary) avg_salary, department_id
    FROM Employees 
    GROUP BY department_id
)

SELECT distinct emp.department_id, dep.department_name
FROM Employees emp
JOIN Departments dep on emp.department_id = dep.department_id
JOIN emp_budget_high ebh on dep.department_id = ebh.department_id
JOIN emp_sal_high esh on dep.department_id = esh.department_id
WHERE  esh.avg_salary > emp.salary; 

































