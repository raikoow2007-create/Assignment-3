BEGIN;

-- =============================================================================
-- TASK 1 & 2: Добавление фильмов и актеров
-- =============================================================================
WITH fav_films AS (
    SELECT 'THE SHAWSHANK REDEMPTION' AS title, 7 AS dur, 4.99 AS rate UNION ALL
    SELECT 'PULP FICTION', 14, 9.99 UNION ALL
    SELECT 'THE MATRIX', 21, 19.99
),
inserted_films AS (
    INSERT INTO film (title, language_id, rental_duration, rental_rate, last_update)
    SELECT ff.title, (SELECT language_id FROM language WHERE name = 'English'), ff.dur, ff.rate, CURRENT_DATE
    FROM fav_films ff
    WHERE NOT EXISTS (SELECT 1 FROM film f WHERE f.title = ff.title)
    RETURNING film_id, title
),
new_actors AS (
    SELECT 'MORGAN' AS fn, 'FREEMAN' AS ln UNION ALL
    SELECT 'TIM', 'ROBBINS' UNION ALL
    SELECT 'JOHN', 'TRAVOLTA' UNION ALL
    SELECT 'UMA', 'THURMAN' UNION ALL
    SELECT 'KEANU', 'REEVES' UNION ALL
    SELECT 'LAURENCE', 'FISHBURNE'
)
INSERT INTO actor (first_name, last_name, last_update)
SELECT na.fn, na.ln, CURRENT_DATE
FROM new_actors na
WHERE NOT EXISTS (SELECT 1 FROM actor a WHERE a.first_name = na.fn AND a.last_name = na.ln);

-- Привязка актеров к фильмам
INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT (SELECT actor_id FROM actor WHERE first_name = 'MORGAN' AND last_name = 'FREEMAN'), (SELECT film_id FROM film WHERE title = 'THE SHAWSHANK REDEMPTION'), CURRENT_DATE UNION ALL
SELECT (SELECT actor_id FROM actor WHERE first_name = 'TIM' AND last_name = 'ROBBINS'), (SELECT film_id FROM film WHERE title = 'THE SHAWSHANK REDEMPTION'), CURRENT_DATE UNION ALL
SELECT (SELECT actor_id FROM actor WHERE first_name = 'JOHN' AND last_name = 'TRAVOLTA'), (SELECT film_id FROM film WHERE title = 'PULP FICTION'), CURRENT_DATE UNION ALL
SELECT (SELECT actor_id FROM actor WHERE first_name = 'UMA' AND last_name = 'THURMAN'), (SELECT film_id FROM film WHERE title = 'PULP FICTION'), CURRENT_DATE UNION ALL
SELECT (SELECT actor_id FROM actor WHERE first_name = 'KEANU' AND last_name = 'REEVES'), (SELECT film_id FROM film WHERE title = 'THE MATRIX'), CURRENT_DATE UNION ALL
SELECT (SELECT actor_id FROM actor WHERE first_name = 'LAURENCE' AND last_name = 'FISHBURNE'), (SELECT film_id FROM film WHERE title = 'THE MATRIX'), CURRENT_DATE
ON CONFLICT DO NOTHING;

-- =============================================================================
-- TASK 3: Добавление в инвентарь
-- =============================================================================
INSERT INTO inventory (film_id, store_id, last_update)
SELECT f.film_id, 1, CURRENT_DATE
FROM film f
WHERE f.title IN ('THE SHAWSHANK REDEMPTION', 'PULP FICTION', 'THE MATRIX')
  AND NOT EXISTS (SELECT 1 FROM inventory i WHERE i.film_id = f.film_id AND i.store_id = 1);

-- =============================================================================
-- TASK 4: Обновление данных клиента 
-- =============================================================================
UPDATE customer
SET first_name = 'RAIYMBEK',           
    last_name = 'SALAMAT',         
    email = 'rsalamat@gmail.com', 
    address_id = (SELECT address_id FROM address LIMIT 1),
    last_update = CURRENT_DATE
WHERE customer_id = 148 OR email = 'rsalamat@example.com'; 

-- =============================================================================
-- TASK 5: Очистка старых записей
-- =============================================================================
-- Проверка и удаление платежей
SELECT * FROM payment WHERE customer_id = (SELECT customer_id FROM customer WHERE email = 'rsalamat@gmail.com');
DELETE FROM payment WHERE customer_id = (SELECT customer_id FROM customer WHERE email = 'rsalamat@gmail.com');

-- Проверка и удаление аренд
SELECT * FROM rental WHERE customer_id = (SELECT customer_id FROM customer WHERE email = 'rsalamat@gmail.com');
DELETE FROM rental WHERE customer_id = (SELECT customer_id FROM customer WHERE email = 'rsalamat@gmail.com');

-- =============================================================================
-- TASK 6: Новая аренда и оплата
-- =============================================================================
WITH new_rentals AS (
    INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
    SELECT 
        '2017-02-01 10:00:00'::timestamp,
        i.inventory_id,
        c.customer_id,
        '2017-02-01 10:00:00'::timestamp + (f.rental_duration * INTERVAL '1 day'),
        (SELECT staff_id FROM staff LIMIT 1),
        CURRENT_DATE
    FROM inventory i
    JOIN film f ON i.film_id = f.film_id
    CROSS JOIN customer c
    WHERE f.title IN ('THE SHAWSHANK REDEMPTION', 'PULP FICTION', 'THE MATRIX')
      AND c.email = 'rsalamat@gmail.com'
    RETURNING rental_id, customer_id, inventory_id
)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT 
    nr.customer_id,
    (SELECT staff_id FROM staff LIMIT 1),
    nr.rental_id,
    f.rental_rate,
    '2017-02-15 14:30:00'::timestamp
FROM new_rentals nr
JOIN inventory i ON nr.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id;

COMMIT;


--TO CHECK

--SELECT title, rental_rate, rental_duration 
--FROM film 
--WHERE title IN ('THE SHAWSHANK REDEMPTION', 'PULP FICTION', 'THE MATRIX');



--SELECT c.first_name, c.last_name, f.title, p.payment_date 
--FROM customer c
--JOIN payment p ON c.customer_id = p.customer_id
--JOIN rental r ON p.rental_id = r.rental_id
--JOIN inventory i ON r.inventory_id = i.inventory_id
--JOIN film f ON i.film_id = f.film_id
--WHERE c.first_name = 'RAIYMBEK''; 
