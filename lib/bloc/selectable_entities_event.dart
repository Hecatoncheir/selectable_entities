part of 'selectable_entities_bloc.dart';

abstract class SelectableEntitiesEvent<T> {}

class EntitySelected<T> extends SelectableEntitiesEvent<T> {
  T entity;
  EntitySelected({required this.entity});
}

class EntityDeselected<T> extends SelectableEntitiesEvent<T> {
  T entity;
  EntityDeselected({required this.entity});
}

class CheckSelectedEntities<T> extends SelectableEntitiesEvent<T> {}

class ExcludeSelectedEntitiesFromAllEntities<T>
    extends SelectableEntitiesEvent<T> {}

class EntitiesFilterChanged<T> extends SelectableEntitiesEvent<T> {
  final EntitiesFilterParameters entitiesFilterParameters;
  EntitiesFilterChanged({
    required this.entitiesFilterParameters,
  });
}
