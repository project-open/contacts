<master src="/packages/contacts/lib/contacts-master" />
<property name="title">@title@: #contacts.Sharing#</property>

<p><a href="@return_url@" class="button">#contacts.Return_to_where_you_were#</a></p>



<h2>#contacts.Sharing#: <if @public_p@>#contacts.Public#</if><else>#contacts.Owners_Only#</else></h2>

<if @admin_p@>
<ul>
<li><a href="@public_url@">#contacts.Change_Sharing#</a></li>
</ul>
</if>
<h2>#contacts.Owners#</h2>

<listtemplate name="owners"></listtemplate>

<p><formtemplate id="add_owner" style="../../../contacts/resources/forms/inline"></formtemplate></p>

