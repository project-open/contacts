<master src="/packages/contacts/lib/contacts-master" />
<br>
<if @default_names@ not nil>
    <table>
        <tr>
        <th width=15%> #contacts.Default_attributes#: </th>
	<td width=90%> @default_names@</td>
	</tr>
    </table>
    <br>
</if>

<listtemplate name="ams_options"></listtemplate>

<br>
<center><a href="search-list">#contacts.Search_List#</a></center>
<br>
&nbsp;
