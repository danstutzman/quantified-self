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

--drop table if exists logs;

create table if not exists logs (
  id integer primary key autoincrement,
  start_date   timestamp not null,
  finish_date  timestamp not null,
  message      varchar(250) not null,
  activity_num integer,
  color        varchar(250),
  created_at   timestamp not null,
  updated_at   timestamp not null
);

--drop table if exists auto_completions;

create table if not exists auto_completions (
  category varchar(250) not null
);

insert into auto_completions (category) values ('bedtime');
insert into auto_completions (category) values ('buy groceries');
insert into auto_completions (category) values ('call someone');
insert into auto_completions (category) values ('chat');
insert into auto_completions (category) values ('clean up');
insert into auto_completions (category) values ('cook');
insert into auto_completions (category) values ('dishes');
insert into auto_completions (category) values ('do laundry');
insert into auto_completions (category) values ('eat');
insert into auto_completions (category) values ('email');
insert into auto_completions (category) values ('facebook');
insert into auto_completions (category) values ('food');
insert into auto_completions (category) values ('groceries');
insert into auto_completions (category) values ('gym');
insert into auto_completions (category) values ('harmonizers');
insert into auto_completions (category) values ('hipchat');
insert into auto_completions (category) values ('laundry');
insert into auto_completions (category) values ('nap');
insert into auto_completions (category) values ('o');
insert into auto_completions (category) values ('phone call');
insert into auto_completions (category) values ('plan');
insert into auto_completions (category) values ('plan lesson');
insert into auto_completions (category) values ('read');
insert into auto_completions (category) values ('relax');
insert into auto_completions (category) values ('run');
insert into auto_completions (category) values ('shower');
insert into auto_completions (category) values ('snack');
insert into auto_completions (category) values ('stretch');
insert into auto_completions (category) values ('walk');
insert into auto_completions (category) values ('wash dishes');
insert into auto_completions (category) values ('youtube');
