FROM fedora:latest

RUN yum check-update; \
    yum install -y gcc openssh-clients wget krb5-workstation libffi-devel python3-devel python3 krb5-devel python3-pip && \
    yum clean all

RUN pip3 install --upgrade pip && \
    pip3 install --upgrade virtualenv && \
    pip3 install pywinrm[kerberos] && \
    pip3 install pywinrm && \
    pip3 install jmespath && \
    pip3 install requests && \
    pip3 install pyvmomi && \
    pip3 install kubernetes && \
    python3 -m pip install ansible

RUN mkdir /ansible && \
    mkdir /root/.kube

COPY src/requirements.yml /ansible
WORKDIR /ansible 
RUN ansible-galaxy collection install -r /ansible/requirements.yml

COPY src/ /ansible
COPY config /root/.kube

