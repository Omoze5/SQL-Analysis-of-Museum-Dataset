DESC work;
-- 1. fetch all the paintings which are not displayed on any museums
SELECT * FROM museum.work;

SELECT name 
FROM 
(SELECT w.name, w.museum_id
from work w 
join museum m 
on w.museum_id = m.museum_id) data
where museum_id is null;

-- There is no paintings that is not displayed in a museum

-- 2. Are there museums without any paintings?

SELECT name, work_id, museum_id
FROM 
(SELECT w.name, w.museum_id, w.work_id
from work w 
join museum m 
on w.museum_id = m.museum_id) data
where work_id is not null and museum_id is null;

select name 
from work 
where museum_id is null;

-- 3. How many paintings have an asking price of more than their regular price?

select count(*)
from product_size
where sale_price > regular_price;
-- none is more than their regular_price

-- 4. identify the painting whose asking price is less than 50% of its regular_price

select w.name, ps.sale_price, ps.regular_price
from work w
join product_size ps
on w.work_id = ps.work_id
where sale_price < 0.5 * regular_price;
-- 27 paintings has an asking price less than 50% of its regular_price

-- 5. which canva size costs the most?

WITH RankedSizes AS (
    SELECT 
        cs.size_id,
        MAX(ps.regular_price) AS max_regular_price,
        RANK() OVER (ORDER BY MAX(ps.regular_price) DESC) AS rnk
    FROM 
        canvas_size cs
    LEFT JOIN 
        product_size ps ON ps.size_id = cs.size_id
    GROUP BY 
        cs.size_id
)
SELECT 
    size_id, 
    max_regular_price, 
    rnk
FROM 
    RankedSizes
WHERE 
    rnk = 1;
-- size_id 4896 and 9648 cost the most with a 2045 dollars regular price


-- 6. DELETE duplicate records from work, product_size, subject and image_link tables
-- for work table
-- delete duplicate rows
DELETE FROM work
WHERE work_id IN (
    SELECT work_id
    FROM (
        SELECT work_id,
               ROW_NUMBER() OVER (PARTITION BY work_id ORDER BY work_id) AS rn
        FROM work
    ) AS work_dup
    WHERE rn > 1
);


-- product_size table
-- Delete duplicate rows

DELETE FROM product_size
WHERE size_id IN (
    SELECT size_id
    FROM (
        SELECT size_id,
               ROW_NUMBER() OVER (PARTITION BY size_id ORDER BY size_id) AS rn
        FROM product_size
    ) AS product_dup
    WHERE rn > 1
    
);

-- subject table
-- delete duplicates table
DELETE FROM subject
WHERE work_id IN (
    SELECT work_id
    FROM (
        SELECT work_id,
               ROW_NUMBER() OVER (PARTITION BY work_id ORDER BY work_id) AS rn
        FROM subject
    ) AS subject_dup
    WHERE rn > 1
    );
        
-- image_link
-- delete duplicates
DELETE FROM image_link
WHERE work_id IN (
    SELECT work_id
    FROM (
        SELECT work_id,
               ROW_NUMBER() OVER (PARTITION BY work_id ORDER BY work_id) AS rn
        FROM image_link
    ) AS subject_dup
    WHERE rn > 1
);

-- all duplicates has been deleted

-- 7. identify the museums with invalid city information in the given dataset

SELECT name, address, city
from museum
where city REGEXP '^[0-9]+$' or city IS NULL;

-- 8. Museum_hours table has 1 invalid entry. identify it and remove it

SELECT *
FROM museum_hours
WHERE close > open;
-- There is no invalid entry 

-- 9. fetch THE TOP 10 most famous painting subject

SELECT NAME, S.SUBJECT, COUNT(NAME)
FROM WORK W 
JOIN subject S 
ON W.WORK_ID = S.work_id
GROUP BY NAME, SUBJECT 
ORDER BY COUNT(NAME) DESC
LIMIT 10;

-- 10. Identify the museums which are open on both sunday and monday, display museum name, city

select m.name, m.city
from museum_hours mh 
JOIN museum m
on mh.museum_id = m.museum_id
WHERE mh.day = 'Sunday' 
and EXISTS (select 1 from museum_hours mh2
             WHERE mh2.museum_id = mh.museum_id
              AND MH2.day = 'Monday');
             
-- 11. How many museums are open every single day
             
select m.name, mh.museum_id, COUNT(DISTINCT mh.day) as no_of_day_of_week
from museum_hours mh
left join museum m 
on mh.museum_id = m.museum_id
GROUP BY m.name, mh.museum_id
HAVING COUNT(DISTINCT mh.day) = 7;
-- 7 museums open all through the day of the week

-- 12. which are the top 5 most popular museum, popularity is based on the most no of paintings in a museum
select m.name, COUNT(DISTINCT w.work_id) as number_painting 
from work w 
left join museum m 
on w.museum_id = m.museum_id
GROUP BY m.name
ORDER BY COUNT(DISTINCT w.work_id) desc
limit 5;
-- the top most museum based on the most number of paintings are The Metropolitan Museum of Art, Rijksmuseum, National Gallery, National Gallery of Art,National Maritime Museum


-- 13. who are top 5 most popular artist, popularity is based on the no of paintings in a museum
select w.artist_id, COUNT(DISTINCT w.work_id) as number_painting
from work w 
left join museum m
on w.museum_id = m.museum_id
GROUP BY w.artist_id
ORDER BY COUNT(DISTINCT w.work_id) DESC
LIMIT 5;

-- 14. Display least popular canva sizes
SELECT size_id, COUNT(*) AS num_occurrences
FROM product_size
GROUP BY size_id
ORDER BY num_occurrences ASC;

-- 15. which museum is open for the longest during the day, display museum, state, and hours open an which day
SELECT
    m.name AS museum_name,
    m.state AS museum_state,
    CAST(mh.open AS TIME) AS opening_time,
    CAST(mh.close AS TIME) AS closing_time,
    TIMEDIFF(mh.open, mh.close) AS duration
FROM
    museum m
LEFT JOIN
    museum_hours mh ON m.museum_id = mh.museum_id
ORDER BY duration DESC;
-- The museum that opens for the longest during the day is the Israel Museum
             
-- 16. Which museum has the most number of popular painting style

SELECT m.name AS MUSEUM_NAME, COUNT(DISTINCT w.style) AS STYLE_COUNT
FROM museum m
LEFT JOIN work w 
ON m.museum_id = w.museum_id
GROUP BY m.name
ORDER BY STYLE_COUNT DESC;
-- The museum with the top most number of popular painting style is The Metropolitan Museum of Art

-- 17. Identify the artist whose paintings are displayed in multiple countries

SELECT artist_id, count(work_id), count(distinct m.country) as Number_Countries
FROM museum.work w 
LEFT JOIN museum m 
ON w.museum_id = m.museum_id
GROUP BY artist_id
ORDER BY count(distinct m.country) desc;

-- 18. Display the country and city with the most number of museums. output 2 separate columns to mention the city and country, 
-- if there are multiple value, separate them withcomma

SELECT 
    GROUP_CONCAT(DISTINCT city ORDER BY num_museums DESC) AS cities,
    GROUP_CONCAT(DISTINCT country ORDER BY num_museums DESC) AS countries
FROM (
    SELECT 
        city,
        country,
        COUNT(*) AS num_museums
    FROM 
        museum
    GROUP BY 
        city, country
) AS museum_counts
ORDER BY 
    num_museums DESC
LIMIT 2;

-- 19. identify the artist and the museum where the most expensive and least expensive painting is placed. 
-- Display the artist name, sale price, painting name, museum name, museum city, and canvas label


-- 20. which country has the 5th highest no of painting
UPDATE museum
SET country = 'United Kingdom'
WHERE country = 'UK';

SELECT m.country, COUNT(DISTINCT w.work_id)
from museum m 
left join work w
on m.museum_id = w.museum_id
GROUP BY m.country
ORDER BY COUNT( w.work_id) desc
LIMIT 1 OFFSET 4;
-- Spain has the 5 highest number of painting

-- 21. Which are the 3 most popular and 3 least popular painting styles?
SELECT style, COUNT(style) AS most_popular
FROM work 
where style <> ''
GROUP BY style
ORDER BY COUNT(*) desc
limit 3;
-- The most popular are Baroque, Impressionism and Rococo

SELECT style, COUNT(style) AS least_popular
FROM work 
where style <> ''
GROUP BY style
ORDER BY COUNT(*) 
limit 3;
-- The least popular are Art Nouveau, surrealism and Naturalism

