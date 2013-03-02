--drop table if exists hipchat_messages;

create table if not exists hipchat_messages (
  id integer primary key autoincrement,
  sender_nick varchar(250),
  message varchar(2000),
  created_at varchar(250),
  updated_at varchar(250)
);

--drop table if exists facebook_messages;

create table if not exists facebook_messages (
  id integer primary key autoincrement,
  from_name varchar(250),
  created_at varchar(250),
  updated_at varchar(250)
);
