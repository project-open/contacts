<master src="/packages/contacts/lib/contact-master">
<property name="party_id">@party_id@</property>

<include src="/packages/contacts/lib/changes" party_id="@party_id@" revision_id=@revision_id@>

<if @revision_id@ not nil>
    <table>
  	<tr>
	    <td>
	        <h3>#contacts.Preview#</h3> 
	    </td>
	</tr>
    	<tr>
	    <td width="50%">
    	        <include src="/packages/contacts/lib/contact-attributes" party_id="@party_id@" revision_id="@revision_id@">
    	    </td>
        </tr>
    </table>
</if>