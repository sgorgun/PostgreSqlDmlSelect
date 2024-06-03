--1. Which staff members made the highest revenue for each store and deserve a bonus for the year 2017?
--V1
WITH staff_revenue AS (
    SELECT
        st.store_id,
        st.staff_id,
        st.first_name,
        st.last_name,
        SUM(p.amount) AS total_revenue
    FROM
        payment p
        JOIN rental r ON p.rental_id = r.rental_id
        JOIN staff st ON p.staff_id = st.staff_id
    WHERE
        p.payment_date >= '2017-01-01' AND p.payment_date < '2018-01-01'
    GROUP BY
        st.store_id, st.staff_id, st.first_name, st.last_name
)
SELECT
    sr.store_id,
    sr.staff_id,
    sr.first_name,
    sr.last_name,
    sr.total_revenue
FROM
    staff_revenue sr
WHERE
    (sr.store_id, sr.total_revenue) IN (
        SELECT
            store_id,
            total_revenue
        FROM
            staff_revenue sr2
        WHERE
            sr2.store_id = sr.store_id
        ORDER BY
            sr2.total_revenue DESC
        LIMIT 2
    )
ORDER BY
    sr.total_revenue DESC
LIMIT 2;
--V2
SELECT
    sr.store_id,
    sr.staff_id,
    sr.first_name,
    sr.last_name,
    sr.total_revenue
FROM (
    SELECT
        st.store_id,
        st.staff_id,
        st.first_name,
        st.last_name,
        SUM(p.amount) AS total_revenue,
        RANK() OVER (PARTITION BY st.store_id ORDER BY SUM(p.amount) DESC) AS revenue_rank
    FROM
        payment p
        JOIN rental r ON p.rental_id = r.rental_id
        JOIN staff st ON p.staff_id = st.staff_id
    WHERE
        p.payment_date >= '2017-01-01' AND p.payment_date < '2018-01-01'
    GROUP BY
        st.store_id, st.staff_id, st.first_name, st.last_name
) sr
WHERE sr.revenue_rank = 1
ORDER BY
    sr.total_revenue DESC;

--2. Which five movies were rented more than the others, and what is the expected age of the audience for these movies?
--V1
SELECT
    f.title,
    sub.rental_count,
    f.rating
FROM
    film f
JOIN
    (
        SELECT 
            i.film_id,
            COUNT(r.rental_id) AS rental_count
        FROM 
            rental r
        JOIN 
            inventory i ON r.inventory_id = i.inventory_id
        GROUP BY 
            i.film_id
        ORDER BY 
            rental_count DESC
        LIMIT 5
    ) sub ON f.film_id = sub.film_id
ORDER BY
    sub.rental_count DESC;
--V2
WITH top_five_films AS (
    SELECT 
        f.film_id,
        f.title, 
        COUNT(r.rental_id) AS rental_count
    FROM 
        rental r
    JOIN 
        inventory i ON r.inventory_id = i.inventory_id
    JOIN 
        film f ON i.film_id = f.film_id
    GROUP BY 
        f.film_id, f.title
    ORDER BY 
        rental_count DESC
    LIMIT 5
)
SELECT
    f.title,
	tf.rental_count,
    f.rating
FROM
    top_five_films tf
JOIN
    film f ON tf.film_id = f.film_id
ORDER BY
    tf.rental_count DESC;

--Which actors/actresses didn't act for a longer period of time than the others?
--V1
SELECT
    a.actor_id,
    a.first_name,
    a.last_name,
    MAX(f.release_year) AS last_release_year,
    EXTRACT(YEAR FROM CURRENT_DATE) - MAX(f.release_year) AS inactivity_period
FROM
    actor a
JOIN
    film_actor fa ON a.actor_id = fa.actor_id
JOIN
    film f ON fa.film_id = f.film_id
GROUP BY
    a.actor_id, a.first_name, a.last_name
ORDER BY
    inactivity_period DESC, a.actor_id;
--V2
WITH last_acting_year AS (
    SELECT
        fa.actor_id,
        MAX(f.release_year) AS last_release_year
    FROM
        film_actor fa
    JOIN
        film f ON fa.film_id = f.film_id
    GROUP BY
        fa.actor_id
)
SELECT
    a.actor_id,
    a.first_name,
    a.last_name,
    lay.last_release_year,
    EXTRACT(YEAR FROM CURRENT_DATE) - lay.last_release_year AS inactivity_period
FROM
    actor a
JOIN
    last_acting_year lay ON a.actor_id = lay.actor_id
ORDER BY
    inactivity_period DESC, a.actor_id;

