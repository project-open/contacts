<master src="/packages/contacts/lib/contacts-master" />
<property name="title">@title@</property>
<property name="context">@context@</property>

<p>
<a href="relationships" class="button">#contacts.Relationships#</a>
<a href="group-ae" class="button">#contacts.Add_Group#</a>
<a href="permissions" class="button">#contacts.lt_Instance_Permissions_#</a>
<a href="@parameter_url@" class="button">#acs-subsite.Parameters#</a>
<a href="@ams_parameter_url@" class="button">#contacts.AMSParameters#</a>
<a href="ext-search-options" class="button">#contacts.Extended_search_opt#</a>
<if @populate_url@ ne ""><a href="@populate_url@" class="button">#contacts.Populate_CRM#</a></if>

</p>
<h1>#contacts.READ_THESE#</h1>
<ul>
  <li>#contacts.lt_Make_sure_you_do_not_#</li>
  <li>#contacts.lt_The_default_group_mus#</li>
</ul>
<p>#contacts.lt_Once_ready_for_releas#</p>
<ul class="action-links">
  <li><a href="@ams_person_url@">Default Person Form</a>
</li>
  <li><a href="@ams_org_url@">Default Organization Form</a></li>
<li><a href="permissions?group_id=@default_group@" class="button">#contacts.Permissions_for_default_group#</a></li>
</ul>
<listtemplate name="groups"></listtemplate>

<h2>#contacts.Exports#</h2>
<p>#contacts.lt_Full_exports_take_a_long_time#</p>
<ul>
  <li><a href="full-people">#contacts.Export_all_people#</a></li>
  <li><a href="full-organizations">#contacts.Export_all_organizations#</a></li>
  <li><a href="full-rels">#contacts.Export_all_relationships#</a></li>
</ul>
