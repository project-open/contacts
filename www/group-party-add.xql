<?xml version="1.0"?>
<queryset>

<fullquery name="insert_state">
    <querytext>
	insert into membership_rels (rel_id,member_state) values (:rel_id,'approved')
    </querytext>
</fullquery>

<fullquery name="update_state">
    <querytext>
	update membership_rels set member_state = 'approved' where rel_id = :rel_id
    </querytext>
</fullquery>

</queryset>
