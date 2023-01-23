## Exercises
{% for section in site.data.exercises %}

### {{ section[0] }}

{% for item in section[1] %}
* [Exercise {{ item.exercise }} - {{ item.name }}](/labguides/ex-{{ item.exercise }}/)
{% endfor %}
{% endfor %}
