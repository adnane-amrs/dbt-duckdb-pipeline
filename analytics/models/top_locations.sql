SELECT 
    job_location,
    COUNT(*) AS postings
FROM {{ ref('job_posting') }}
GROUP BY job_location 
ORDER BY postings DESC
LIMIT 10