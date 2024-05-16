use learning

/* 1. Provide a list of products with a base price greater than 500 and that are featured in promo type of 'BOGOF (Buy 1 get 1 for free) */
select distinct product_name,
    base_price
from fact_events e
inner join dim_products p on e.product_code = p.product_code
where base_price > 500 and promo_type = 'BOGOF'
;

/* 2. Generatae a report that provides an overview of the number of stores in each city.
The results will be sorted in descending order of store counts, allowing us to identify the cities with the highest store presence.
The report includes two essential fields: city and store count, which will assist in optimizing operations. */
select city,
    count(distinct store_id) store_count
from dim_stores
group by city
order by store_count desc
;

/* 3. Generate a report that displays each campaign along with the total revenue generated before and after the campaign.
The report includes three key fields: campaign_name, total_revenue_before_promo, total_revenue_after_promo.
This report should help in evaluation the financial impact of our promotional campaigns. (display the values in millions) */

/*select distinct promo_type from fact_events*/
with cte AS
(
select campaign_name,
    (1.0* base_price * quantity_sold_before_promo) as total_revenue_before_promo,
    (case
    when promo_type = '50% OFF' then base_price * 0.5 * quantity_sold_after_promo
    when promo_type = 'BOGOF' then base_price * 0.5 * 2 * quantity_sold_after_promo
    when promo_type = '25% OFF' then base_price * (1-0.25) * quantity_sold_after_promo
    when promo_type = '33% OFF' then base_price * (1-0.33) * quantity_sold_after_promo
    else base_price * quantity_sold_after_promo END) as total_revenue_after_promo
from fact_events e
inner join dim_campaigns c on e.campaign_id = c.campaign_id
)
select campaign_name, concat(round(sum(total_revenue_before_promo)/1000000, 2),'M') as total_revenue_before_promo, concat(round(sum(total_revenue_after_promo)/1000000,2),'M') as total_revenue_after_promo
from cte
group by campaign_name
;


/* 4. Produce a report that calculates the Incremental Sold Quantity (ISU%) for each category during the Diwali campaign.
Additionally, provide rankings for the categories based on their ISU%. The report will include three key fields: category, ISU% and rank order.
This information will assist in the assessing the category-wise success and impact of the Diwali campaign on incremental sales.

Note: ISU% is calculated as the percentage increase/decrease in quantity sold (after promo) compared to quantity sold (before promo) */


with temp as
(
select p.category,
    sum(quantity_sold_before_promo) as total_quantity_before_promo,
    sum(quantity_sold_after_promo) as total_quantity_after_promo,
    round(sum(quantity_sold_after_promo)*100.0/sum(quantity_sold_before_promo),2) as ISU
from fact_events e
inner join dim_campaigns c on e.campaign_id = c.campaign_id
inner join dim_products p on e.product_code = p.product_code
where campaign_name = 'Diwali'
group by p.category
)
select *,
    rank() over(order by ISU desc) as ranked
from temp
order by ranked ASC
;

/* 5. Create a report featureing the Top 5 Products, ranked by Incremental Revenue Percentage (IR%), across all campaigns.
The report will provide essential information including product name, category, and IR%. This analysis helps identify
the most successful products in terms of incremental revenue across our campaigns, assisting in product organization. */
with temp as
(
select p.product_name,
    p.category,
    (1.0* base_price * quantity_sold_before_promo) as total_revenue_before_promo,
    (case
    when promo_type = '50% OFF' then base_price * 0.5 * quantity_sold_after_promo
    when promo_type = 'BOGOF' then base_price * 0.5 * 2 * quantity_sold_after_promo
    when promo_type = '25% OFF' then base_price * (1-0.25) * quantity_sold_after_promo
    when promo_type = '33% OFF' then base_price * (1-0.33) * quantity_sold_after_promo
    else base_price * quantity_sold_after_promo END) as total_revenue_after_promo
from fact_events e
inner join dim_products p on e.product_code = p.product_code
)
select product_name,
    category,
    sum(total_revenue_before_promo) total_revenue_before_promo,
    sum(total_revenue_after_promo) total_revenue_after_promo,
    round(sum(total_revenue_after_promo)*100.0/sum(total_revenue_before_promo), 2) IR
from temp
group by product_name, category
order by IR desc
;


/*
select top 5 * from dim_campaigns;

select top 5 * from dim_products;

select top 5 * from dim_stores;

select top 5 * from fact_events;

select distinct promo_type from fact_events;
*/