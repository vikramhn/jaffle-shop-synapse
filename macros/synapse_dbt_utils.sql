{% macro synapse__test_expression_is_true(model, expression, column_name) %}

select
    1 as dbt_expression
from {{ model }}
{% if column_name is none %}
where not({{ expression }})
{%- else %}
where not({{ column_name }} {{ expression }})
{%- endif %}

{% endmacro %}
