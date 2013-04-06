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
  id integer           primary key autoincrement,
  start_date           char(19) not null,
  finish_date          char(19) not null,
  start_date_seconds   integer not null,
  finish_date_seconds  integer not null,
  intention            varchar(250) not null,
  category             varchar(250) not null,
  created_at           timestamp not null,
  updated_at           timestamp not null
);

--drop table if exists categories;

create table if not exists categories (
  category varchar(250) not null
);

insert into categories (category) values ('real-social');
insert into categories (category) values ('domestic');
insert into categories (category) values ('exercise');
insert into categories (category) values ('improve');
insert into categories (category) values ('sleep');
insert into categories (category) values ('virtual-social');
insert into categories (category) values ('work');
insert into categories (category) values ('zone-out');

--drop table if exists auto_completions;

create table if not exists auto_completions (
  category varchar(250) not null,
  intention varchar(250) not null
);

insert into auto_completions (category, intention) values ('zone-out',       'bedtime');
insert into auto_completions (category, intention) values ('domestic',       'buy groceries');
insert into auto_completions (category, intention) values ('virtual-social', 'call someone');
insert into auto_completions (category, intention) values ('virtual-social', 'chat');
insert into auto_completions (category, intention) values ('domestic',       'clean up');
insert into auto_completions (category, intention) values ('domestic',       'cook');
insert into auto_completions (category, intention) values ('domestic',       'dishes');
insert into auto_completions (category, intention) values ('domestic',       'do laundry');
insert into auto_completions (category, intention) values ('domestic',       'eat');
insert into auto_completions (category, intention) values ('virtual-social', 'email');
insert into auto_completions (category, intention) values ('zone-out',       'facebook');
insert into auto_completions (category, intention) values ('domestic',       'groceries');
insert into auto_completions (category, intention) values ('exercise',       'gym');
insert into auto_completions (category, intention) values ('real-social',    'harmonizers');
insert into auto_completions (category, intention) values ('virtual-social', 'hipchat');
insert into auto_completions (category, intention) values ('domestic',       'laundry');
insert into auto_completions (category, intention) values ('sleep',          'nap');
insert into auto_completions (category, intention) values ('zone-out',       'o');
insert into auto_completions (category, intention) values ('work',           'onlinerubytutor');
insert into auto_completions (category, intention) values ('virtual-social', 'phone call');
insert into auto_completions (category, intention) values ('zone-out',       'read');
insert into auto_completions (category, intention) values ('zone-out',       'relax');
insert into auto_completions (category, intention) values ('exercise',       'run');
insert into auto_completions (category, intention) values ('domestic',       'shower and dress');
insert into auto_completions (category, intention) values ('sleep',          'sleep');
insert into auto_completions (category, intention) values ('zone-out',       'snack');
insert into auto_completions (category, intention) values ('zone-out',       'stretch');
insert into auto_completions (category, intention) values ('work',           'student-checklist');
insert into auto_completions (category, intention) values ('work',           'teach class');
insert into auto_completions (category, intention) values ('zone-out',       'walk');
insert into auto_completions (category, intention) values ('domestic',       'wash dishes');
insert into auto_completions (category, intention) values ('zone-out',       'youtube');
