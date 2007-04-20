<if @contacts_master_template@ eq /packages/contacts/lib/contacts-master>
  <master>
  <property name="title">@title@</property>
  <property name="context">@context@</property>
  <property name="header_stuff">
    <link href="/resources/contacts/contacts.css" rel="stylesheet" type="text/css">
  </property>
  <property name="navbar_list">@navbar@</property>
  <if @focus@ not nil>
    <property name="focus">@focus@</property>
  </if>
  <div id="section">
    <ul>
    <multiple name="links">
      <li><a href="@links.url@" title="Go to @links.label@" id="@links.id@" onmouseover="@links.mouseover;noquote@"><if @links.selected_p@><strong></if>@links.label@<if @links.selected_p@></strong></if></a><if @links:rowcount@ eq @links.rownum@><em>&nbsp;</em></if> </li>
    </multiple>
    </ul>
  </div>
</if>
<else>
  <master src="@contacts_master_template@">
  <property name="title">@title@</property>
  <property name="context">@context@</property>
  <property name="header_stuff">
    <link href="/resources/contacts/contacts.css" rel="stylesheet" type="text/css">
  </property>
</else>

@js_script;noquote@
<slave>


