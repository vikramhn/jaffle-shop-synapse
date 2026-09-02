with location_order_summary as (

    select
        l.location_id,
        l.location_name,
        l.opened_date,
        l.tax_rate,
        count(o.order_id) as total_orders,
        coalesce(sum(o.order_total), cast(0.00 as decimal(18, 2))) as total_revenue,
        coalesce(sum(o.order_cost), cast(0.00 as decimal(18, 2))) as total_cost,
        coalesce(avg(o.order_total), cast(0.00 as decimal(18, 2))) as average_order_value

    from {{ ref('locations') }} as l
    left join {{ ref('orders') }} as o
        on l.location_id = o.location_id

    group by
        l.location_id,
        l.location_name,
        l.opened_date,
        l.tax_rate

),

profitability as (

    select
        location_id,
        location_name,
        opened_date,
        tax_rate,
        total_orders,
        total_revenue,
        total_cost,
        average_order_value,
        cast(total_revenue - total_cost as decimal(18, 2)) as gross_profit

    from location_order_summary

)

select
    location_id,
    location_name,
    opened_date,
    tax_rate,
    total_orders,
    total_revenue,
    total_cost,
    average_order_value,
    gross_profit,
    case
        when total_revenue = 0 then cast(0.00 as decimal(18, 2))
        else cast((gross_profit / total_revenue) * 100 as decimal(18, 2))
    end as profit_margin_pct

from profitability