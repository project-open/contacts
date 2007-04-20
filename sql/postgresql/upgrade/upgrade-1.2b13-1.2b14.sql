-- 
-- packages/contacts/sql/postgresql/upgrade/upgrade-1.2d13-1.2d14.sql
-- 
-- @author Matthew Geddert (openacs@geddert.com)
-- @creation-date 2006-06-01
-- @arch-tag: 
-- @cvs-id $Id$
--

create table contact_privacy (
        party_id        integer primary key
                        constraint contact_privacy_party_id_fk references parties(party_id) on delete cascade,
        email_p         boolean not null default 't',
        mail_p          boolean not null default 't',
        phone_p         boolean not null default 't',
        gone_p          boolean not null default 'f' -- if a person is deceased or an organization is closed down
                        constraint contact_privacy_gone_p_ck check (
                               ( gone_p is TRUE AND ( mail_p is FALSE and email_p is FALSE and phone_p is FALSE ))
                            or ( gone_p is FALSE )
                        )
);

insert into contact_privacy
( party_id, email_p, mail_p, phone_p, gone_p )
select party_id, 't'::boolean, 't'::boolean, 't'::boolean, 'f'::boolean
  from parties
 where party_id not in ( select party_id from contact_privacy )
 order by party_id;

