{% from "logstash/map.jinja" import logstash with context %}
{% set zip_url = salt['pillar.get']('kibana:zip_url', 'http://download.elasticsearch.org/kibana/kibana/kibana-latest.zip') %}
{% set root_path = salt['pillar.get']('kibana:root_path', '/srv/www/kibana') %}
{% set kibana_port = salt['pillar.get']('kibana:port', 9000 ) %}
{% set elasticsearch_url = salt['pillar.get']('kibana:elasticsearch_url', salt['grains.get']('fqdn')) %}
{% set hostname = salt['pillar.get']('kibana:server_name', salt['grains.get']('fqdn')) %}

kibana_reqs:
  pkg.installed:
    - pkgs:
      - {{ logstash.git }}
      - {{ logstash.wget }}
      - {{ logstash.unzip }}

{{ root_path }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

check_for_kibana:
  cmd.run:
    - name: "[ -d {{ root_path }}/kibana-latest ]; if [ $? == 0 ] ; then echo changed=no; else echo changed=yes; fi"
    - stateful: True

download_kibana:
  cmd.wait:
    - name: {{ logstash.wget }} {{ zip_url }}
    - user: root
    - cwd: /tmp
    - watch:
      - cmd: check_for_kibana
    - require:
      - file: {{ root_path }}
      - pkg: kibana_reqs

extract_kibana:
  cmd.wait:
    - name: {{ logstash.unzip }} kibana-latest.zip -d {{ root_path }}
    - cwd: /tmp
    - user: root
    - watch:
      - cmd: download_kibana

kibana_config:
  file.managed:
    - name: {{ root_path }}/kibana-latest/config.js
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - source: salt://logstash/files/kibana_config.js
    - context:
        hostname: {{ hostname }}
        root_path: {{ root_path }}
        elasticsearch_url: {{ elasticsearch_url }}
