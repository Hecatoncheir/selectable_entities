part of 'selectable_entities_bloc.dart';

abstract class SelectableEntitiesState<T> {}

class EntitySelect<T> extends SelectableEntitiesState<T> {
  T entity;
  List<T> selectedEntities;

  EntitySelect({
    required this.entity,
    required this.selectedEntities,
  });
}

class EntityDeselect<T> extends SelectableEntitiesState<T> {
  T entity;
  List<T> selectedEntities;

  EntityDeselect({
    required this.entity,
    required this.selectedEntities,
  });
}

class SelectedEntitiesChanged<T> extends SelectableEntitiesState<T> {
  final List<T> entities;
  SelectedEntitiesChanged({
    required this.entities,
  });
}

class EntitiesChanged<T> extends SelectableEntitiesState<T> {
  final List<T> entities;
  final EntitiesFilterParameters? filterParameters;

  EntitiesChanged({
    required this.entities,
    this.filterParameters,
  });
}
