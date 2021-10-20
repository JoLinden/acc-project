FROM ubuntu
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get install -y git
RUN apt-get install -y python3-pip
RUN pip3 install --upgrade pip
ADD . .
RUN pip3 install --no-cache-dir --retries=15 -r requirements.txt
CMD python3 client.py