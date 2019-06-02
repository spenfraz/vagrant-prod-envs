# vagrant-prod-envs
Production environments for mwsu-schedule-api on CentOS 7 and Ubuntu 18.

-----
---> ubuntu_mwsu-schedule-api_prod OR cent_mwsu-schedule-api_prod

##### 1. Ensure Vagrant and Virtualbox are installed.
##### 2. Clone
    $ git clone https://github.com/spenfraz/vagrant-prod-envs.git
##### 3. Navigate
    $ cd ./vagrant-prod-envs/ubuntu_mwsu-schedule-api_prod OR ./vagrant-prod-envs/cent_mwsu-schedule-api_prod
##### 4. Run
    $ vagrant up
##### 5. Check it out (after previous step finishes)
http://localhost:3000/sections, http://localhost:3000/sections?limit=20&find=courseID-BIO ,   
http://localhost:3000/sections?find=courseID-CSC3&fields=instructor-title-courseID-days-time ,  
http://localhost:3000/sections?find=title-nurs&fields=instructor-title-courseID-days-time&limit=30 ,  
http://localhost:3000/departments , http://localhost:3000/subjects

__resources:__  
  * https://www.digitalocean.com/community/tutorials/how-to-serve-flask-applications-with-gunicorn-and-nginx-on-centos-7  
  * https://www.digitalocean.com/community/tutorials/how-to-serve-flask-applications-with-gunicorn-and-nginx-on-ubuntu-18-04  
