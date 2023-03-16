#!/bin/bash

###############################################################################
# This script outputs a list of vacant jobs listed on forasna.com where the   #
# number of available positions exceed the number of applicants               #
#                                                                             #
# Output format:                                                              #
# job post URL, job field, job speciality, job title, address, date published #
###############################################################################

# vacant jobs URL
URL='https://forasna.com/%D9%88%D8%B8%D8%A7%D8%A6%D9%81-%D8%AE%D8%A7%D9%84%D9%8A%D8%A9'

temp_dir='/tmp/forasna.com_scraper'

# output file containing list of job post URLs
output_file="postings-`date +\%Y-\%m-\%d-\%H-\%M-\%S`.csv"

mkdir -p ${temp_dir}

# remove newline characters for grep pattern matching
wget -q -O ${temp_dir}/job_list_raw.html ${URL}
cat ${temp_dir}/job_list_raw.html | tr -d '
' > ${temp_dir}/job_list.html

jobs_count=`grep -o 'class="search-jobs-count">[^<]\+' ${temp_dir}/job_list.html | awk -F '>' '{print $2}'`

echo 'Found '${jobs_count}' job posts. Scraping...'

jobs_count=`echo ${jobs_count} | tr -d ','`

num_fetched=0
while [[ "${num_fetched}" -lt "${jobs_count}" ]]; do 

	job_list=`grep -o '<h2 class="job-title">[[:space:]]*<a[[:space:]]\+onclick="[^"]\+"[[:space:]]\+title="[^"]\+"[[:space:]]\+target="[^"]\+"[[:space:]]\+href="[^"]\+"' ${temp_dir}/job_list.html | awk -F '"' '{print $10}'`

	num_jobs=`echo ${job_list} | tr ' ' '\n' | wc -l`

	((num_fetched+=num_jobs))

	for job_post_URL in ${job_list}; do

		# remove newline characters for grep pattern matching
		wget -q -O ${temp_dir}/post_raw.html ${job_post_URL}
		cat ${temp_dir}/post_raw.html | tr -d '
' > ${temp_dir}/post.html

		# number of available positions
		available=`grep -o 'class="item-info">[[:space:]]*[0-9]\+[[:space:]]*<' ${temp_dir}/post.html | awk -F ' ' '{print $2}'`

		# number of applicants
		applicants=`grep -o '<ul class="job-nums">[[:space:]]*<[^>]\+>[[:space:]]*<span class="num">[[:space:]]*[0-9]\+[[:space:]]*' ${temp_dir}/post.html | awk -F '>' '{print $4}' | tr -d ' '`

		main_work_field=`grep -o 'Main Work Field[^>]\+>[^<]\+' ${temp_dir}/post.html | awk -F '>' '{print $2}'`
		
		sub_work_field=`grep -o 'Sub Work Field[^>]\+>[^<]\+' ${temp_dir}/post.html | awk -F '>' '{print $2}'`

		datetime_post=`grep -o 'datetime="[^"]\+" itemprop="datePosted"' ${temp_dir}/post.html | awk -F '"' '{print $2}'`

		job_title=`grep -o 'itemprop="title" content="[^"]\+' ${temp_dir}/post.html | awk -F '"' '{print $4}'`

		address_region=`grep -o 'addressRegion"[^"]\+"[^"]\+' ${temp_dir}/post.html | awk -F '"' '{print $3}'`
		address_country=`grep -o 'addressCountry"[^"]\+"[^"]\+' ${temp_dir}/post.html | awk -F '"' '{print $3}'`
		address_locality=`grep -o 'addressLocality"[^"]\+"[^"]\+' ${temp_dir}/post.html | awk -F '"' '{print $3}'`

		if [[ "${available}" -gt "${applicants}" ]]; then
		
			echo "Adding ${job_post_URL},${main_work_field},${sub_work_field},${job_title},${address_region},${address_country},${address_locality},${datetime_post}"
			echo "Number of job posts fetched so far: ${num_fetched}"

			echo ${job_post_URL},${main_work_field},${sub_work_field},${job_title},${address_region},${address_country},${address_locality},${datetime_post} >> ${output_file}
		fi

	done
	
	echo 'Fetching '"${URL}?start=${num_fetched}"
	
	# fetch next page
	wget -q -O ${temp_dir}/job_list_raw.html "${URL}?start=${num_fetched}"
	
	# remove newline characters for grep pattern matching
	cat ${temp_dir}/job_list_raw.html | tr -d '
' > ${temp_dir}/job_list.html

done
