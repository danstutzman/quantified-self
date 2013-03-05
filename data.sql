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

--drop table if exists unanswered_messages;

create table if not exists unanswered_messages (
  id          integer primary key autoincrement,
  email_uid   integer,
  medium      varchar(250),
  sender      varchar(250),
  decision    varchar(250),
  was_seen    boolean,
  received_at timestamp,
  created_at  timestamp,
  updated_at  timestamp
);

--drop table if exists tasks;

create table if not exists tasks (
  id          integer primary key autoincrement,
  name        varchar(250) not null,
  estimate    float,
  priority    char(1),
  created_at  timestamp not null,
  updated_at  timestamp not null
);

--drop table if exists task_burndown_updates;

create table if not exists task_burndown_updates (
  id          integer primary key autoincrement,
  created_at  timestamp not null,
  hours_left  float
);
insert into task_burndown_updates (created_at, hours_left) values ('2013-03-05 09:00:00', 10);
insert into task_burndown_updates (created_at, hours_left) values ('2013-03-05 12:00:00', 5);
