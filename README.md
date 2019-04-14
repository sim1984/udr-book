Руководство по написанию UDR на Pascal
======================================

Данное руководство описывает процесс написания UDR (внеших поцедур, функций,
триггеров) на языке Object Pascal. Практически все примеры в руководстве
написаны так чтобы их можно было скопмилировать как на Delphi XE и так и на Free
Pascal (FPC 3.0 и старше).

 

Ссылки
------

Готовый PDF документ вы можете скачать по ссылке
[UDR.pdf](https://github.com/sim1984/udr-book/releases/download/1/udr.pdf)

Примеры UDR на языке pascal находятся в
[examples](https://github.com/sim1984/udr-book/tree/master/examples)

1.  [Простейшие процедуры, функции и триггеры](https://github.com/sim1984/udr-book/tree/master/examples/01.%20SumArgs)
2.  [Работа с IMessageMetadata](https://github.com/sim1984/udr-book/tree/master/examples/02.%20SumArgs_MessageMetadata)
3.  [Совместное использование IMessageMetadata и статических структур](https://github.com/sim1984/udr-book/tree/master/examples/03.%20SumArgs_Mixed)
4.  [Процедура Split для разбияния BLOB по разделителю](https://github.com/sim1984/udr-book/tree/master/examples/04.%20Split)
5.  [Сохранение и загрузка BLOB в/из файла](https://github.com/sim1984/udr-book/tree/master/examples/05.%20BlobSaveLoad)
6.  [Функция получение плана для заданного запроса](https://github.com/sim1984/udr-book/tree/master/examples/07.%20ExplainPlan)
7.  [Функция сериализации результатов запроса в Json в контексте текущего соединения и транзакции](https://github.com/sim1984/udr-book/tree/master/examples/08.%20Json)
8.  [Использование метода setup в фабрике функции](http://github.com/sim1984/udr-book/tree/master/examples/09.%20Setup_method)
9.  [Улучшенный процедура split для различных типов данных](http://github.com/sim1984/udr-book/tree/master/examples/10.%20BlobSplit)

### Внимание

В настоящий момент руководство находится на начальной стадии написания и может
содержать множество ошибок.
