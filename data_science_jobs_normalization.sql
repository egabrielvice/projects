-- Create normalized tables
CREATE TABLE jobs (
  job_id SERIAL PRIMARY KEY,
  job_link TEXT UNIQUE
);

CREATE TABLE skills (
  skill_id SERIAL PRIMARY KEY,
  skill_name TEXT UNIQUE
);

CREATE TABLE job_skills (
  job_id INTEGER REFERENCES jobs(job_id),
  skill_id INTEGER REFERENCES skills(skill_id),
  PRIMARY KEY (job_id, skill_id)
);

CREATE TABLE raw_job_skills (
  job_link TEXT,
  job_skills TEXT
);

-- Insert distinct job links
INSERT INTO jobs (job_link)
SELECT DISTINCT job_link
FROM raw_job_skills
WHERE job_link IS NOT NULL;

-- Insert distinct skills
INSERT INTO skills (skill_name)
SELECT DISTINCT trim(skill)
FROM (
  SELECT unnest(string_to_array(job_skills, ',')) AS skill
  FROM raw_job_skills
) AS all_skills
WHERE trim(skill) <> '';

-- Link jobs to skills safely (skip duplicates)
INSERT INTO job_skills (job_id, skill_id)
SELECT j.job_id, s.skill_id
FROM raw_job_skills r
JOIN jobs j ON r.job_link = j.job_link
JOIN LATERAL unnest(string_to_array(r.job_skills, ',')) AS skill_array(skill_text) ON TRUE
JOIN skills s ON trim(skill_array.skill_text) = s.skill_name
ON CONFLICT DO NOTHING;

-- Top 10 most frequent skills
SELECT s.skill_name, COUNT(js.job_id) AS frequency
FROM job_skills js
JOIN skills s ON js.skill_id = s.skill_id
GROUP BY s.skill_name
ORDER BY frequency DESC
LIMIT 10;