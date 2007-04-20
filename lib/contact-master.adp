<if @contact_master_template@ eq /packages/contacts/lib/contact-master>
  <master>
  <property name="title">@title@</property>
  <property name="context">@context@</property>
  <property name="header_stuff">
    <link href="/resources/contacts/contacts.css" rel="stylesheet" type="text/css">
  </property>
  <if @focus@ not nil>
    <property name="focus">@focus@</property>
  </if>
  <div id="section">
    <ul>
    <multiple name="links">
      <li><a href="@links.url@" title="Go to @links.label@"><if @links.selected_p@><strong></if>@links.label@<if @links.selected_p@></strong></if></a><if @links:rowcount@ eq @links.rownum@ and @public_url@ nil><em>&nbsp;</em></if> </li>
    </multiple>
    <if @public_url@ not nil>
      <li><a href="@public_url@" title="Go to this community member's public page">#contacts.Public_Page#</a><em>&nbsp;</em> </li>
    </if>
    </ul>
  </div>
</if>
<else>
  <master src="@contact_master_template@">
  <property name="party_id">@party_id@</property>
  <if @title@ not nil><property name="title">@title;noquote@</property></if>
  <if @context@ not nil><property name="context">@context;noquote@</property></if>
</else>

<slave>
