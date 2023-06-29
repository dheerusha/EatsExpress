CREATE TABLE goldusers_signup(userid integer, gold_signup_date date);

INSERT INTO goldusers_signup(userid, gold_signup_date)
VALUES (1,'09-22-2017'),
(3,'04-21-2017')

CREATE TABLE sales(userid integer, created_date date, product_id integer);

INSERT INTO sales(userid, created_date, product_id)
VALUES(1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


CREATE TABLE product(product_id integer, product_name text, price integer);


INSERT INTO product(product_id, product_name, price)
VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


CREATE TABLE users(userid integer, signup_date date);

INSERT INTO users(userid, signup_date)
VALUES(1,'09-02-2014'),
(2,'01-15-1015'),
(3,'04-11-2014');


SELECT* FROM sales;
SELECT* FROM product;
SELECT* FROM goldusers_signup;
SELECT* FROM users;


1) What is the total amount each customer spent on EatsExpress?

SELECT 
  a.userid, 
  SUM(b.price) total_amount_spent 
FROM 
  sales a 
  INNER JOIN product b on a.product_id = b.product_id 
GROUP BY 
  a.userid;


2)How many days has each customer visited EatsExpress?
SELECT 
  userid, 
  COUNT(DISTINCT created_date) distinct_days 
FROM 
  sales 
GROUP BY 
  userid;

3) What was the first product purchased by each customer?
SELECT 
  * 
FROM 
  (
    SELECT 
      *, 
      RANK() OVER (
        PARTITION BY userid 
        ORDER BY
          created_date
      ) rnk 
    FROM 
      sales
  ) a 
WHERE 
  rnk = 1;



4) What is the most purchased item on the menu 
and how many times was it purchased by all customers?

SELECT 
  userid, 
  COUNT(product_id) cnt 
FROM 
  sales 
WHERE 
  product_id = (
    SELECT 
      TOP 1 product_id 
    FROM 
      sales 
    GROUP BY 
      product_id 
    ORDER BY 
      COUNT(product_id) DESC
  ) 
GROUP BY 
  userid;


5) Which item was most popular for each customer?

SELECT 
  * 
FROM 
  (
    SELECT 
      *, 
      RANK() OVER(
        PARTITION BY userid 
        ORDER BY 
          cnt DESC
      ) rnk 
    FROM 
      (
        SELECT 
          userid, 
          product_id, 
          COUNT(product_id) cnt 
        FROM 
          sales 
        GROUP BY 
          userid, 
          product_id
      ) a
  ) b 
WHERE 
  rnk = 1;


6) Which item was purchased first by the customer
after they became a member?

SELECT 
  * 
FROM 
  (
    SELECT 
      c.*, 
      RANK() OVER(
        PARTITION BY userid 
        ORDER BY 
          created_date
      ) rnk 
    FROM 
      (
        SELECT 
          a.userid, 
          a.created_date, 
          a.product_id, 
          b.gold_signup_date 
        FROM 
          sales a 
          INNER JOIN goldusers_signup b ON a.userid = b.userid 
          and a.created_date >= b.gold_signup_date
      ) c
  ) d 
WHERE 
  rnk = 1;



7) Which item was purchased just before the customer became a member?

SELECT 
  * 
FROM 
  (
    SELECT 
      c.*, 
      RANK() OVER(
        PARTITION BY userid 
        ORDER BY 
          created_date DESC
      ) rnk 
    FROM 
      (
        SELECT 
          a.userid, 
          a.created_date, 
          a.product_id, 
          b.gold_signup_date 
        FROM 
          sales a 
          INNER JOIN goldusers_signup b ON a.userid = b.userid 
          and a.created_date <= b.gold_signup_date
      ) c
  ) d 
WHERE 
  rnk = 1;



8) What is the total orders and amount spent
for each member before they become a member?

SELECT 
  userid, 
  COUNT(created_date) order_purchased, 
  SUM(price) total_amt_spent 
FROM 
  (
    SELECT 
      c.*, 
      d.price 
    FROM 
      (
        SELECT 
          a.userid, 
          a.created_date, 
          a.product_id, 
          b.gold_signup_date 
        FROM 
          sales a 
          INNER JOIN goldusers_signup b ON a.userid = b.userid 
          and a.created_date <= b.gold_signup_date
      ) c 
      INNER JOIN product d ON c.product_id = d.product_id
  ) e 
GROUP BY 
  userid;



9) IF buying each product generates points for eg 5rs = 2 EatsExpress point and
each product has different purchasing points for eg for p1 5rs=1 EatsExpress point,
for p2 10rs = 5 EatsExpresszomato point and p3 5rs = 1 EatsExpress point,
calculate points collected by each customers and for which product most points have
been given till now.
Points collected by each customers:

SELECT 
  userid, 
  SUM(total_points)* 2.5 total_money_earned 
FROM 
  (
    SELECT 
      e.*, 
      amt / points total_points 
    FROM 
      (
        SELECT 
          d.*, 
          CASE WHEN product_id = 1 THEN 5 WHEN product_id = 2 THEN 2 WHEN product_id = 3 THEN 5 ELSE 0 END AS points 
        FROM 
          (
            SELECT 
              c.userid, 
              c.product_id, 
              SUM(price) amt 
            FROM 
              (
                SELECT 
                  a.*, 
                  b.price 
                FROM 
                  sales a 
                  INNER JOIN product b ON a.product_id = b.product_id
              ) c 
            GROUP BY 
              userid, 
              product_id
          ) d
      ) e
  ) f 
GROUP BY 
  userid;



For which product most points have been given till now:

SELECT 
  * 
FROM 
  (
    SELECT 
      *, 
      RANK() OVER(
        ORDER BY 
          total_points_earned DESC
      ) rnk 
    FROM 
      (
        SELECT 
          product_id, 
          SUM(total_points) total_points_earned 
        FROM 
          (
            SELECT 
              e.*, 
              amt / points total_points 
            FROM 
              (
                SELECT 
                  d.*, 
                  CASE WHEN product_id = 1 THEN 5 WHEN product_id = 2 THEN 2 WHEN product_id = 3 THEN 5 ELSE 0 END AS points 
                FROM 
                  (
                    SELECT 
                      c.userid, 
                      c.product_id, 
                      sum(price) amt 
                    FROM 
                      (
                        SELECT 
                          a.*, 
                          b.price 
                        FROM 
                          sales a 
                          INNER JOIN product b ON a.product_id = b.product_id
                      ) c 
                    GROUP BY 
                      userid, 
                      product_id
                  ) d
              ) e
          ) f 
        GROUP BY 
          product_id
      ) f
  ) g 
WHERE 
  rnk = 1;




10) In the first one year after a customer joins the gold program (including their join date)
irrespective of what the customer has purchased they earn 5 zomato points for every 10 rs spent
who earned more 1 or 3 and what their points earning in their first year?

SELECT 
  c.*, 
  d.price * 0.5 total_points_earned 
FROM 
  (
    SELECT 
      a.userid, 
      a.created_date, 
      a.product_id, 
      b.gold_signup_date 
    FROM 
      sales a 
      INNER JOIN goldusers_signup b on a.userid = b.userid 
      AND a.created_date >= b.gold_signup_date 
      AND created_date <= DATEADD(YEAR, 1, gold_signup_date)
  ) c 
  INNER JOIN product d ON c.product_id = d.product_id;



11) Rank all the transaction of the customers

SELECT 
  *, 
  RANK() OVER (
    PARTITION BY userid 
    ORDER BY 
      created_date
  ) rnk 
FROM 
  sales;



12) Rank all the transaction for each member whenever they are a EatsExpress gold member
for every non gold member transaction mark as NA

SELECT 
  e.*, 
  CASE WHEN rnk = 0 THEN 'NA' ELSE rnk END AS rnkk 
FROM 
  (
    SELECT 
      c.*, 
      CAST(
        (
          CASE WHEN gold_signup_date is null THEN 0 ELSE RANK() OVER(
            PARTITION BY userid 
            ORDER BY 
              created_date DESC
          ) END
        ) AS VARCHAR
      ) rnk 
    FROM 
      (
        SELECT 
          a.userid, 
          a.created_date, 
          a.product_id, 
          b.gold_signup_date 
        FROM 
          sales a 
          LEFT JOIN goldusers_signup b ON a.userid = b.userid 
          AND a.created_date >= b.gold_signup_date
      ) c
  ) e;

