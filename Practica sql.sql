select distinct
    p.nombre 'Nombre', p.apellido 'Apellido', p.dni 'Dni'
from
    personas p
        inner join
    contratos c ON c.dni = p.dni
        inner join
    empresas e ON e.cuit = c.cuit
where
    e.cuit in (select 
            cuit
        from
            contratos
                inner join
            personas ON personas.dni = contratos.dni
        where
            personas.nombre = 'Stefania'
                and personas.apellido = 'Lopez');

select distinct
    p.dni, concat(p.nombre, ' ', p.apellido)
from
    personas p
        inner join
    contratos c ON p.dni = c.dni
where
    c.sueldo < (select 
            max(contratos.sueldo)
        from
            empresas
                inner join
            contratos ON contratos.cuit = empresas.cuit
        where
            empresas.razon_social = 'Viejos Amigos');

select 
    em.cuit, em.razon_social, avg(importe_comision) prom
from
    empresas em
        inner join
    contratos co ON em.cuit = co.cuit
        inner join
    comisiones com ON com.nro_contrato = co.nro_contrato
group by em.cuit , em.razon_social
having prom >= (select 
        avg(importe_comision)
    from
        empresas em
            inner join
        contratos co ON em.cuit = co.cuit
            inner join
        comisiones com ON com.nro_contrato = co.nro_contrato
    where
        em.razon_social = 'Viejos Amigos');
select distinct
    em.razon_social,
    com.importe_comision,
    com.mes_contrato,
    com.anio_contrato,
    com.nro_contrato,
    p.nombre,
    p.apellido
from
    personas p
        inner join
    contratos con ON p.dni = con.dni
        inner join
    empresas em ON em.cuit = con.cuit
        inner join
    comisiones com ON com.nro_contrato = con.nro_contrato
where
    com.importe_comision < (select 
            avg(importe_comision)
        from
            comisiones);

select distinct
    em.razon_social, avg(com.importe_comision)
from
    empresas em
        inner join
    contratos con ON em.cuit = con.cuit
        inner join
    comisiones com ON con.nro_contrato = com.nro_contrato
group by em.razon_social
having avg(com.importe_comision) > (select 
        avg(importe_comision)
    from
        comisiones);

select distinct
    concat(personas.apellido, ' ', personas.nombre) 'Nombre y apellido'
from
    personas
        inner join
    personas_titulos ON personas.dni = personas_titulos.dni
where
    personas_titulos.cod_titulo not in (select 
            titulos.cod_titulo
        from
            titulos
        where
            titulos.tipo_titulo in ('Educacion No formal' , 'Terciario'));

#Ej 7
create temporary table sueldo_promedio
select contratos.cuit, avg(contratos.sueldo) promedio
from contratos
group by contratos.cuit;

select distinct
    personas.dni,
    concat(personas.nombre, ' ', personas.apellido),
    empresas.cuit,
    contratos.sueldo
from
    personas
        inner join
    contratos ON contratos.dni = personas.dni
        inner join
    empresas ON empresas.cuit = contratos.cuit
        inner join
    sueldo_promedio ON sueldo_promedio.cuit = empresas.cuit
where
    sueldo_promedio.promedio < contratos.sueldo;

#Ej 8
create temporary table empresas_promedio
select distinct empresas.razon_social, avg(comisiones.importe_comision) promedio
from empresas
inner join contratos
on contratos.cuit = empresas.cuit
inner join comisiones
on comisiones.nro_contrato = contratos.nro_contrato
group by empresas.razon_social;

set @max = (select max(emp.promedio)from empresas_promedio emp);
set @min = (select min(emp.promedio)from empresas_promedio emp);

select 
    empresas_promedio.razon_social, promedio
from
    empresas_promedio
where
    empresas_promedio.promedio in (@max , @min);

#Ej 9 base de datos afatse
# Alumnos que se hayan inscripto a mÃ¡s cursos que Antoine de Saint-Exupery. Mostrar todos
#los datos de los alumnos, la cantidad de cursos a la que se inscribiÃ³ y cuantas veces mÃ¡s
#que Antoine de Saint-Exupery.


set @cant= ( select count(*) 
from alumnos 
inner join inscripciones 
on alumnos.dni = inscripciones.dni
where (alumnos.nombre = "Antoine de") and (alumnos.apellido = "Saint-Exupery"));


select 
    alumnos.dni, nombre, apellido, count(*), count(*) - @cant
from
    alumnos
        inner join
    inscripciones ON alumnos.dni = inscripciones.dni
group by alumnos.dni , nombre , apellido
having count(*) > @cant;

#Ej 10
/*En el aÃ±o 2014, quÃ© cantidad de alumnos se han inscripto a los Planes de CapacitaciÃ³n
indicando para cada Plan de CapacitaciÃ³n la cantidad de alumnos inscriptos y el porcentaje
que representa respecto del total de inscriptos a los Planes de CapacitaciÃ³n dictados en el
aÃ±o.*/




create temporary table anio2014
select inscripciones.nom_plan, count(*) cuenta
from inscripciones
inner join alumnos
on inscripciones.dni = alumnos.dni
where inscripciones.fecha_inscripcion between "2014-01-01" and "2014-12-31" 
group by inscripciones.nom_plan;

set @total =

(
	select sum(cuenta) from anio2014

);

select 
    anio2014.nom_plan, cuenta, (cuenta / @total)
from
    anio2014;


#Ej 11

#Indicar el valor actual de los planes de capacitaciÃ³n.

drop table if exists maximos;
create temporary table maximos
select nom_plan, max(fecha_desde_plan ) max
from valores_plan
group by nom_plan;

drop table if exists valoresactuales;
create temporary table valoresactuales
select valores_plan.nom_plan, valores_plan.fecha_desde_plan, valores_plan.valor_plan
from valores_plan
inner join maximos
on maximos.nom_plan = valores_plan.nom_plan
where maximos.max = valores_plan.fecha_desde_plan;

select 
    *
from
    valoresactuales;

#Ej 12
#Plan de capacitaciÃ³n mÃ¡s barato. Indicar los datos del plan de capacitaciÃ³n y el valor
#actual.
/*Uso la tabla temporal creada en el ejercicio anterior*/

set @minimo = (select min(valoresactuales.valor_plan) from valoresactuales);


select 
    pc.nom_plan,
    pc.desc_plan,
    pc.hs,
    pc.modalidad,
    va.valor_plan,
    @minimo
from
    plan_capacitacion pc
        inner join
    valoresactuales va ON va.nom_plan = pc.nom_plan
where
    va.valor_plan = @minimo;

(select distinct
    em.cuit,
    razon_social,
    pe.dni,
    pe.nombre,
    pe.apellido,
    ca.cod_cargo,
    ca.desc_cargo,
    ('Contratos-empresas')
from
    empresas em
        inner join
    contratos co ON em.cuit = co.cuit
        inner join
    cargos ca ON ca.cod_cargo = co.cod_cargo
        inner join
    personas pe ON pe.dni = co.dni
order by razon_social) union (select 
    em.cuit,
    razon_social,
    pe.dni,
    pe.nombre,
    pe.apellido,
    ca.cod_cargo,
    ca.desc_cargo,
    ('Antecedentes')
from
    empresas em
        inner join
    antecedentes an ON em.cuit = an.cuit
        inner join
    cargos ca ON ca.cod_cargo = an.cod_cargo
        inner join
    personas pe ON pe.dni = an.dni
order by razon_social desc);


/* 2 De las empresas registradas interesa la cantidad de personas que podemos tener como
contacto por haber sido contratadas y cantidad de personas que podemos tener como
contacto por ser registrada como antecedente. Mostrar tambiÃ©n las empresas que no
tienen personas como contacto tanto en contratos como en antecedentes. Indicar el
porcentaje que representa respecto al total de personas que tenemos registradas.*/
select 
    count(*)
into @ cantidadTotalPersonas from
    personas;
(select 
    emp.cuit 'Cuit',
    emp.razon_social 'Razon',
    count(co.nro_contrato),
    ('Contactos por contrato') 'Cualidad',
    (count(co.nro_contrato) / @cantidadTotalPersonas) Promedio
from
    empresas emp
        left join
    contratos co ON emp.cuit = co.cuit
group by emp.cuit) union (select 
    em.cuit 'Cuit',
    em.razon_social 'Razon',
    count(distinct an.dni),
    ('Contactos por antecedente') 'Cualidad',
    (count(an.dni) / @cantidadTotalPersonas) Promedio
from
    empresas em
        left join
    antecedentes an ON em.cuit = an.cuit
group by em.cuit);

/* Listar las empresas solicitantes mostrando la razón social y fecha de cada solicitud, y
descripción del cargo solicitado. Si hay empresas que no hayan solicitado que muestre la
leyenda: Sin Solicitudes en la fecha y en la descripción del cargo. Además mostrar todos los
cargos incluso los que no han sido solicitados nunca, en ese caso indicar en razón social y
fecha de solicitud la leyenda “Cargo no solicitado”.*/


(select distinct
    ifnull(empresas.razon_social,
            'cargo no solicitado'),
    solicitudes_empresas.fecha_solicitud,
    ifnull(cargos.desc_cargo,
            'sin solicitudes a la fecha')
from
    empresas
        left join
    solicitudes_empresas ON empresas.cuit = solicitudes_empresas.cuit
        left join
    cargos ON cargos.cod_cargo = solicitudes_empresas.cod_cargo) union (select distinct
    ifnull(empresas.razon_social,
            'cargo no solicitado'),
    solicitudes_empresas.fecha_solicitud,
    ifnull(cargos.desc_cargo,
            'sin solicitudes a la fecha')
from
    cargos
        left join
    solicitudes_empresas ON solicitudes_empresas.cod_cargo = cargos.cod_cargo
        left join
    empresas ON empresas.cuit = solicitudes_empresas.cuit);

/*4) Listado de personas que hayan sido contratadas y que existan registradas también con sus
antecedentes. Si se repiten mostrarlas una sola vez.*/

select 
    *
from
    personas
        inner join
    contratos ON personas.dni = contratos.dni
where
    exists( select 
            *
        from
            personas_titulos);

#practica 8
/* 1) Agregar el nuevo instructor Daniel Tapia con cuil: 44-44444444-4, teléfono: 444-444444,
email: dotapia@gmail.com, dirección Ayacucho 4444 y sin supervisor.*/

insert into instructores (cuil, nombre, apellido, tel, email, direccion, cuil_supervisor) 
values (44-44444444-4,'Daniel',' Tapia','444444444', 'dotapia@gmail.com','ayacucho 444',null);

/*2) Ingresar un nuevo plan de capacitación con sus datos, costo, temas, exámenes y
materiales:
Plan:
Nombre: Administrador de BD, descripción: Instalación y configuración MySQL. Lenguaje
SQL. Usuarios y permisos, de 300 hs con modalidad presencial*/

start transaction;
insert into plan_capacitacion ( nom_plan, desc_plan, hs, modalidad)
values ('Administrador de BD','Instalación y configuración MySQL. Lenguaje SQL. Usuarios y permisos',300 , 'Presencial');
insert into plan_temas ( nom_plan, titulo, detalle)
values ('Administrador de BD', 'Instalacion MySql','Distintas configuraciones de instalaciòn');
insert into plan_temas ( nom_plan, titulo, detalle)
values ('Administrador de BD', 'Configuracion DBMS','Variables de entorno, su uso y configuración');
insert into plan_temas ( nom_plan, titulo, detalle)
values ('Administrador de BD', 'Lenguaje SQL','DML, DDL y TCL');
insert into plan_temas ( nom_plan, titulo, detalle)
values ('Administrador de BD','Lenguaje SQL','DML, DDL y TCL');
insert into plan_temas ( nom_plan, titulo, detalle)
values ('Administrador de BD','Usuarios y permisos','Permisos de usuarios y DCL');
insert INTO examenes (nom_plan,nro_examen) VALUES ( 'Administrador de BD',1);
insert INTO examenes (nom_plan,nro_examen) VALUES ( 'Administrador de BD',2);
insert INTO examenes (nom_plan,nro_examen) VALUES ( 'Administrador de BD',3);
insert INTO examenes (nom_plan,nro_examen) VALUES ( 'Administrador de BD',4);
insert INTO examenes_temas (nom_plan,nro_examen) VALUES ( 'Administrador de BD',1,'Instalacion MySql');
#Continuar...........


## rollback;
commit;


CREATE TABLE `alumnos_historico` (
    `dni` int(11) NOT NULL,
    `fecha_hora_cambio` datetime NOT NULL,
    `nombre` varchar(20) DEFAULT NULL,
    `apellido` varchar(20) DEFAULT NULL,
    `tel` varchar(20) DEFAULT NULL,
    `email` varchar(50) DEFAULT NULL,
    `direccion` varchar(50) DEFAULT NULL,
    `usuario_modificacion` varchar(50) DEFAULT NULL,
    `tipo_mov` varchar(45) DEFAULT NULL,
    PRIMARY KEY (`dni` , `fecha_hora_cambio`),
    CONSTRAINT `alumnos_historico_alumnos_fk` FOREIGN KEY (`dni`)
        REFERENCES `alumnos` (`dni`)
        ON UPDATE CASCADE
)  ENGINE=InnoDB DEFAULT CHARSET=utf8;



## click derecho en la tabla -> alter table -> triggers


USE `afatse`;
DELIMITER $$      /* cambia de ; a $$ para delimitar sentencias*/
CREATE TRIGGER `alumnos_AINS` AFTER INSERT ON `alumnos` FOR EACH ROW /*hasta aca lo hace solo */
begin
	INSERT INTO alumnos_historico
	values (new.dni, current_timestamp, new.nombre, new.apellido,
new.tel, new.email, new.direccion, current_user(),"Insert");
end$$
delimiter ; /*vuelve al ;*/


USE `afatse`;
DELIMITER $$
CREATE TRIGGER `alumnos_AUPD` AFTER UPDATE ON `alumnos` FOR EACH ROW
begin
	INSERT INTO alumnos_historico
	values (old.dni, current_timestamp, old.nombre, old.apellido,
old.tel, old.email, old.direccion, current_user(),"update");
end$$
delimiter ;

## 2        EN FERRETERIA

CREATE TABLE `stock_movimientos` (
`cod_material` char(6) NOT NULL,
`fecha_movimiento` timestamp NOT NULL default CURRENT_TIMESTAMP on update
CURRENT_TIMESTAMP,
`cantidad_movida` int(11) NOT NULL,
`cantidad_restante` int(11) NOT NULL,
`usuario_movimiento` varchar(50) NOT NULL,
PRIMARY KEY (`cod_material`,`fecha_movimiento`),
CONSTRAINT `stock_movimientos_fk` FOREIGN KEY (`cod_material`) REFERENCES
`materiales` (`cod_material`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

USE `afatse`;

DELIMITER $$

DROP TRIGGER IF EXISTS afatse.materiales_AINS$$
USE `afatse`$$
CREATE TRIGGER `materiales_AINS` AFTER INSERT ON `materiales` FOR EACH ROW
BEGIN
	insert into stock_movimientos (cod_material, cantidad_movida,
	cantidad_restante, usuario_movimiento) 
	values (new.cod_material, new.cant_disponible,new.cant_disponible,current_user());
end;$$
DELIMITER ;

##falta el de update



