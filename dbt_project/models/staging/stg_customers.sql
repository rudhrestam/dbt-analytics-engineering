select
    cast(customer_id as integer)        as customer_id,
    trim(full_name)                     as full_name,
    lower(trim(email))                  as email,
    cast(signup_date as date)           as signup_date,
    trim(home_store)                    as home_store
from {{ source('raw_data', 'raw_customers') }}
