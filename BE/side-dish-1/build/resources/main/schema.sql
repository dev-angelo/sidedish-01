drop table if exists item;
drop table if exists category;
drop table if exists banchan;


create table CATEGORY (
    id int primary key auto_increment,
    categoryName varchar(128)
);

create table BANCHAN (
    id int primary key auto_increment,
    name varchar(128),
    price varchar (128),
    category_id int references category(id)
);

create table IMAGE (
    id int primary key auto_increment,
    url varchar(128),
    banchan int references BANCHAN(id)
);

