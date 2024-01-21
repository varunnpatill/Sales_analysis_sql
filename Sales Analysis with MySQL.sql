use orders;
show tables;

-- 1. Write a query to display customer full name with their title (Mr/Ms), both first name and
-- last name are in upper case, customer email id, customer creation date and display
-- customer’s category after applying below categorization rules:
-- i. IF customer creation date Year <2005 Then Category A
-- ii. IF customer creation date Year >=2005 and <2011 Then Category B
-- iii. iii)IF customer creation date Year>= 2011 Then Category C

select * from online_customer;

with mycte as 
(select *, if(oc.customer_gender = 'F','Ms',if(oc.customer_gender = 'M','Mr',null)) as title from online_customer as oc)
select upper(concat(title, customer_fname,' ',customer_lname)) as customer_name,
customer_email as email, customer_phone as phone_number,
customer_creation_date as customer_creation_date,
if(year(customer_creation_date) < '2005','A',if(year(customer_creation_date) >= '2005' and year(customer_creation_date) < '2011','B',
if(year(customer_creation_date) >= '2011','C',null))) as customer_category
from mycte;


-- Write a query to display the following information for the products, which have not
-- been sold: product_id, product_desc, product_quantity_avail, product_price, inventory
-- values (product_quantity_avail*product_price), New_Price after applying discount as per
-- below criteria. Sort the output with respect to decreasing value of Inventory_Value.
-- i) IF Product Price > 20,000 then apply 20% discount
-- ii) IF Product Price > 10,000 then apply 15% discount
-- iii) IF Product Price =< 10,000 then apply 10% discount 

select * from product;

SELECT 
    p.product_id AS product_id,
    p.product_desc AS product_name,
    p.product_quantity_avail AS product_quantity_available,
    p.product_price,
    SUM(p.product_quantity_avail * p.product_price) AS inventory_value,
    ROUND(CASE
                WHEN p.product_price > 20000 THEN p.product_price - p.product_price * 20 / 100
                WHEN p.product_price > 10000 THEN p.product_price - p.product_price * 15 / 100
                ELSE p.product_price - p.product_price * 15 / 100
            END,
            2) AS new_price_after_discount
FROM
    product AS p
GROUP BY p.product_id , p.product_desc , p.product_quantity_avail , p.product_price
ORDER BY inventory_value DESC;

-- Write a query to display Product_class_code, Product_class_description, Count of
-- Product type in each product class, Inventory Value
-- (product_quantity_avail*product_price).
-- Information should be displayed for only those product_class_code which have more than
-- 1,00,000. Inventory Value. Sort the output with respect to decreasing value of
-- Inventory_Value

select * from product_class;

SELECT 
    pc.product_class_code,
    pc.product_class_desc AS category,
    COUNT(p.product_id) AS total_product_types,
    SUM(p.product_quantity_avail * p.product_price) AS inventory_value
FROM
    product p
        LEFT JOIN
    product_class pc ON p.product_class_code = pc.product_class_code
GROUP BY pc.product_class_code , pc.product_class_desc
HAVING SUM(product_quantity_avail * product_price) > 100000
ORDER BY inventory_value;

--  Write a query to display customer_id, full name, customer_email, customer_phone and
-- country of customers who have cancelled all the orders placed by them 

select * from order_header;

SELECT 
    oc.customer_id,
    CONCAT(oc.customer_fname,
            ' ',
            oc.customer_lname) AS customer_name,
    oc.customer_email AS email,
    oc.customer_phone AS phone_number,
    a.country AS customer_country,
    'Cancelled' AS order_status
FROM
    online_customer oc
        LEFT JOIN
    address a ON oc.address_id = a.address_id
WHERE
    oc.customer_id IN (SELECT 
            customer_id
        FROM
            order_header
        WHERE
            order_status = 'Cancelled');

-- Write a query to display Shipper name, City to which it is catering, num of customer
-- catered by the shipper in the city and number of consignments delivered to that city for
-- Shipper DHL

SELECT 
    s.shipper_name,
    a.city,
    COUNT(oc.customer_id) AS total_customer_catered,
    COUNT(IF(oh.order_status = 'Shipped', 1, NULL)) AS no_of_consignments
FROM
    online_customer oc
        LEFT JOIN
    order_header oh ON oc.customer_id = oh.customer_id
        LEFT JOIN
    shipper s ON oh.shipper_id = s.shipper_id
        LEFT JOIN
    address a ON oc.address_id = a.address_id
WHERE
    s.shipper_name = 'DHL'
GROUP BY s.shipper_name , a.city;

-- Write a query to display product_id, product_desc, product_quantity_avail, quantity sold
-- and show inventory Status of products as below as per below condition:
-- i. For Electronics and Computer categories, if sales till date is Zero then show 'No
-- Sales in past, give discount to reduce inventory', if inventory quantity is less than
-- 10% of quantity sold, show 'Low inventory, need to add inventory', if inventory
-- quantity is less than 50% of quantity sold, show 'Medium inventory, need to add
-- some inventory', if inventory quantity is more or equal to 50% of quantity sold,
-- show 'Sufficient inventory'
-- ii. For Mobiles and Watches categories, if sales till date is Zero then show 'No Sales in
-- past, give discount to reduce inventory', if inventory quantity is less than 20% of
-- quantity sold, show 'Low inventory, need to add inventory', if inventory quantity is
-- less than 60% of quantity sold, show 'Medium inventory, need to add some
-- inventory', if inventory quantity is more or equal to 60% of quantity sold, show
-- 'Sufficient inventory'
-- iii. Rest of the categories, if sales till date is Zero then show 'No Sales in past, give
-- discount to reduce inventory', if inventory quantity is less than 30% of quantity
-- sold, show 'Low inventory, need to add inventory', if inventory quantity is less than
-- 70% of quantity sold, show 'Medium inventory, need to add some inventory', if 
-- inventory quantity is more or equal to 70% of quantity sold, show 'Sufficient inventory

select * from product_class;
select * from product;

SELECT 
    p.product_id,
    p.product_desc,
    pc.product_class_desc,
    SUM(p.product_quantity_avail) AS product_quantity_avail,
    SUM(o.product_quantity) AS product_quantity,
    CASE
        WHEN
            pc.product_class_desc IN ('electronics' , 'computer')
                AND (o.product_quantity = 0
                OR o.product_quantity IS NULL)
        THEN
            'no sales in past , give discount to reduce
            inventory'
        WHEN
            pc.product_class_desc IN ('electronics' , 'computer')
                AND (p.product_quantity_avail < 0.1 * o.product_quantity)
        THEN
            'low inventory ,need to
            add inventory'
        WHEN
            pc.product_class_desc IN ('electronics' , 'computer')
                AND (p.product_quantity_avail < 0.5 * o.product_quantity)
        THEN
            'medium inventory, need
            to add some inventory'
        WHEN
            pc.product_class_desc IN ('electronics' , 'computer')
                AND (p.product_quantity_avail >= 0.5 * o.product_quantity)
        THEN
            'sufficient inventory'
        WHEN
            pc.product_class_desc IN ('mobiles' , 'watches')
                AND (o.product_quantity = 0
                OR o.product_quantity IS NULL)
        THEN
            'no sales in past , give discount to reduce inventory'
        WHEN
            pc.product_class_desc IN ('mobiles' , 'watches')
                AND (p.product_quantity_avail < 0.2 * o.product_quantity)
        THEN
            'low inventory ,need to
            add inventory'
        WHEN
            pc.product_class_desc IN ('mobiles' , 'watches')
                AND (p.product_quantity_avail < 0.6 * o.product_quantity)
        THEN
            'medium inventory, need
            to add some inventory'
        WHEN
            pc.product_class_desc IN ('mobiles' , 'watches')
                AND (p.product_quantity_avail >= 0.6 * o.product_quantity)
        THEN
            'sufficient inventory'
        WHEN
            pc.product_class_desc NOT IN ('mobiles' , 'watches', 'electronics', 'computer')
                AND (o.product_quantity = 0
                OR o.product_quantity IS NULL)
        THEN
            'no sales in past ,
            give discount to reduce inventory'
        WHEN
            pc.product_class_desc NOT IN ('mobiles' , 'watches', 'electronics', 'computer')
                AND (p.product_quantity_avail < 0.3 * o.product_quantity)
        THEN
            'low inventory ,need
            to add inventory'
        WHEN
            pc.product_class_desc NOT IN ('mobiles' , 'watches', 'electronics', 'computer')
                AND (p.product_quantity_avail < 0.7 * o.product_quantity)
        THEN
            'medium inventory,
            need to add some inventory'
        WHEN
            pc.product_class_desc NOT IN ('mobiles' , 'watches', 'electronics', 'computer')
                AND (p.product_quantity_avail >= 0.7 * o.product_quantity)
        THEN
            'sufficient
            inventory'
    END AS inventory_status
FROM
    product p
        LEFT JOIN
    order_items o ON p.product_id = o.product_id
        LEFT JOIN
    product_class pc ON p.product_class_code = pc.product_class_code
GROUP BY 1 , 2 , 3 , 6;


-- Write a query to display order_id and volume of the biggest order (in terms of volume)
-- that can fit in carton id 10 

select * from carton;

SELECT 
    ord.order_id, (p.len * p.width * p.height) product_volume
FROM
    product p
        JOIN
    order_items ord USING (product_id)
WHERE
    (p.len * p.width * p.height) <= (SELECT 
            (c.len * c.width * c.height) carton_volume
        FROM
            carton c
        WHERE
            carton_id = 10)
ORDER BY product_volume DESC
LIMIT 1;


-- Write a query to display customer id, customer full name, total quantity and total value
-- (quantity*price) shipped where mode of payment is Cash and customer last name starts
-- with 'G' 

select * from order_header;

SELECT 
    c.customer_id,
    CONCAT(customer_fname, ' ', customer_lname) AS full_name,
    SUM(o.product_quantity) AS total_quantity,
    SUM(o.product_quantity * p.product_price) AS total_value
FROM
    online_customer c
        JOIN
    order_header oh ON c.customer_id = oh.customer_id
        JOIN
    order_items o ON oh.order_id = o.order_id
        JOIN
    product p ON o.product_id = p.product_id
WHERE
    payment_mode = 'cash'
        AND customer_lname LIKE 'G%'
GROUP BY customer_id;



-- Write a query to display product_id, product_desc and total quantity of products which
-- are sold together with product id 201 and are not shipped to city Bangalore and New
-- Delhi


SELECT 
    p.product_id,
    p.product_desc,
    SUM(o.product_quantity) AS total_quantity
FROM
    product p
        JOIN
    order_items o ON p.product_id = o.product_id
        JOIN
    order_header oh ON o.order_id = oh.order_id
        JOIN
    online_customer oc ON oh.customer_id = oc.customer_id
        JOIN
    address a ON oc.address_id = a.address_id
WHERE
    o.order_id IN (SELECT 
            o.order_id
        FROM
            order_items
        WHERE
            product_id = '201'
                AND oh.order_status = 'shipped'
                AND a.city NOT IN ('Bangalore' , 'New Delhi'))
GROUP BY p.product_id , p.product_desc
ORDER BY total_quantity DESC;


-- Write a query to display the order_id,customer_id and customer fullname, total
-- quantity of products shipped for order ids which are even and shipped to address where
-- pincode is not starting with "5" 

SELECT 
    oh.order_id,
    oc.customer_id,
    CONCAT(customer_fname, ' ', customer_lname) AS name,
    SUM(o.product_quantity) AS total_quantity
FROM
    online_customer oc
        JOIN
    order_header oh ON oc.customer_id = oh.customer_id
        JOIN
    order_items o ON oh.order_id = o.order_id
        JOIN
    address a ON oc.address_id = a.address_id
WHERE
    o.order_id % 2 = 0
        AND a.pincode NOT LIKE '5%'
GROUP BY 1 , 2;





