# This is the main state file for deploying certificates

{% from "cert/map.jinja" import map with context %}

# Install required packages
cert_packages:
  pkg.installed:
    - pkgs:
{% for pkg in map.pkgs %}
      - {{ pkg }}
{% endfor %}

# Deploy certificates
# Place all files in a files_roots/cert, e.g. /srv/salt/files/cert/

{% for name, data in salt['pillar.get']('cert:certlist', {}).items() %}

  {% set cert = data.get('cert', False) %}
  {% set key = data.get('key', False) %}
  {% set cert_user = data.get('cert_user', map.cert_user) %}
  {% set key_user = data.get('key_user', map.key_user) %}
  {% set cert_group = data.get('cert_group', map.cert_group) %}
  {% set key_group = data.get('key_group', map.key_group) %}
  {% set cert_mode = data.get('cert_mode', map.cert_mode) %}
  {% set key_mode = data.get('key_mode', map.key_mode) %}
  {% set cert_dir = data.get('cert_dir', map.cert_dir) %}
  {% set key_dir = data.get('key_dir', map.key_dir) %}
  {% set keys_from_source_dir = data.get('keys_from_source_dir', map.keys_from_source_dir) %}

{{ cert_dir }}/{{ name }}:
  file.managed:
{% if cert %}
    - contents: |
{{ cert|indent(8, True) }}
{% else %}
    - source: {{ map.cert_source_dir }}{{ name }}
{% endif %}
    - user: {{ cert_user }}
    - group: {{ cert_group }}
    - mode: {{ cert_mode }}

  {% if key or keys_from_source_dir %}
{{ key_dir }}/{{ name }}.key:
  file.managed:
    {%- if keys_from_source_dir %}
    - source: {{ map.cert_source_dir }}{{ name }}.key
    {%- else %}
    - contents: |
{{ key|indent(8, True) }}
    {%- endif %}
    - user: {{ key_user }}
    - group: {{ key_group }}
    - mode: {{ key_mode }}
  {% endif %}

{% if grains['os_family']=="Debian" %}
  cmd.run:
    - name: update-ca-certificates
    - runas: root
    - onchanges:
      - file: {{ cert_dir }}/{{ name }}
{% endif %}

{% endfor %}
