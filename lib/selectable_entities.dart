import 'package:flutter/material.dart';

import 'bloc/selectable_entities_bloc.dart';
export 'bloc/selectable_entities_bloc.dart';

typedef EntitiesDecorator = Widget Function(BuildContext, Widget);

class SelectableEntities<T> extends StatefulWidget {
  final bool isScrollbarAlwaysShown;
  final bool withFilter;
  final InputDecoration? fieldNameDecoration;

  final SelectableEntitiesBloc bloc;

  final Widget Function(BuildContext, T) _entityBuilder;
  final Widget Function(BuildContext, T) _selectedEntityBuilder;

  final Function(T, List<T>)? _onEntitySelected;
  final Function(T, List<T>)? _onEntityDeselected;

  final EntitiesDecorator? _entitiesDecorator;

  const SelectableEntities({
    required this.bloc,
    required Widget Function(BuildContext, T) entityBuilder,
    required Widget Function(BuildContext, T) selectedEntityBuilder,
    Function(T, List<T>)? onEntitySelected,
    Function(T, List<T>)? onEntityDeselected,
    Key? key,
    bool this.withFilter = false,
    bool this.isScrollbarAlwaysShown = true,
    EntitiesDecorator? entitiesDecorator,
    this.fieldNameDecoration,
  })  : _entityBuilder = entityBuilder,
        _selectedEntityBuilder = selectedEntityBuilder,
        _onEntitySelected = onEntitySelected,
        _onEntityDeselected = onEntityDeselected,
        _entitiesDecorator = entitiesDecorator,
        super(key: key);

  @override
  _SelectableEntitiesState<T> createState() => _SelectableEntitiesState<T>();
}

class _SelectableEntitiesState<T> extends State<SelectableEntities<T>> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkSelectedEntitiesEvent = CheckSelectedEntities<T>();
    widget.bloc.eventController.add(checkSelectedEntitiesEvent);

    if (widget.withFilter) {
      final entitiesFilterChangedEvent = EntitiesFilterChanged<T>(
        entitiesFilterParameters: EntitiesFilterParameters(name: ""),
      );

      widget.bloc.eventController.add(entitiesFilterChangedEvent);
    } else {
      final excludeSelectedEntitiesFromAllEntities =
          ExcludeSelectedEntitiesFromAllEntities<T>();
      widget.bloc.eventController.add(excludeSelectedEntitiesFromAllEntities);
    }

    widget.bloc.stateStream.listen((state) {
      if (state is EntitySelect<T>) {
        final selectedEntity = state.entity;
        final selectedEntities = state.selectedEntities;

        final callback = widget._onEntitySelected;
        if (callback != null) {
          callback(selectedEntity, selectedEntities);
        }
      }

      if (state is EntityDeselect<T>) {
        final deselectedEntity = state.entity;
        final selectedEntities = state.selectedEntities;

        final callback = widget._onEntityDeselected;
        if (callback != null) {
          callback(deselectedEntity, selectedEntities);
        }
      }
    });

    return buildLayout(context);
  }

  Widget buildLayout(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSelectableEntitiesLayout(context),
        Expanded(
          child: buildAllEntitiesLayout(context),
        ),
      ],
    );
  }

  Widget buildSelectableEntitiesLayout(BuildContext _) {
    return StreamBuilder<SelectableEntitiesState>(
      stream: widget.bloc.stateStream
          .where((state) => state is SelectedEntitiesChanged<T>),
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state is SelectedEntitiesChanged<T>) {
          final selectedEntities = state.entities;

          return buildSelectableEntities(context, selectedEntities);
        }

        return Container();
      },
    );
  }

  Widget buildFilterLayout(
    BuildContext context,
    EntitiesFilterParameters? parameters,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: buildFilter(context, parameters),
    );
  }

  Widget buildFilter(
    BuildContext _,
    EntitiesFilterParameters? parameters,
  ) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(6),
                    ),
                    color: Colors.white,
                  ),
                  child: TextFormField(
                    key: const Key("FormField-Name"),
                    initialValue: parameters?.name,
                    onChanged: (text) {
                      final filterParameters = parameters;
                      filterParameters?.name = text;

                      final event = EntitiesFilterChanged<T>(
                        entitiesFilterParameters: filterParameters,
                      );

                      widget.bloc.eventController.add(event);
                    },
                    decoration: widget.fieldNameDecoration != null
                        ? widget.fieldNameDecoration
                        : InputDecoration(
                            hintText: 'Name',
                            isDense: true,
                            border: const OutlineInputBorder(gapPadding: 0),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildAllEntitiesLayout(BuildContext _) {
    return StreamBuilder<SelectableEntitiesState>(
      stream:
          widget.bloc.stateStream.where((state) => state is EntitiesChanged<T>),
      builder: (context, snapshot) {
        final state = snapshot.data;

        if (state is EntitiesChanged<T>) {
          final entities = state.entities;

          final decorator = widget._entitiesDecorator;

          return decorator == null
              ? buildAllEntitiesWithFilter(
                  context,
                  state.filterParameters,
                  entities,
                )
              : decorator(
                  context,
                  buildAllEntitiesWithFilter(
                    context,
                    state.filterParameters,
                    entities,
                  ),
                );
        }

        return Container();
      },
    );
  }

  Widget buildAllEntitiesWithFilter(
    BuildContext context,
    EntitiesFilterParameters? entitiesFilterParameters,
    List<T> entities,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.withFilter)
          buildFilterLayout(
            context,
            entitiesFilterParameters,
          ),
        Flexible(
          child: buildAllEntities(
            context,
            entities,
          ),
        ),
      ],
    );
  }

  Widget buildAllEntities(
    BuildContext context,
    List<T> entities,
  ) {
    const _wrapSpacing = 6.0;

    return Scrollbar(
      isAlwaysShown: widget.isScrollbarAlwaysShown,
      controller: _scrollController,
      interactive: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Wrap(
          spacing: _wrapSpacing,
          children: [
            for (final entity in entities) buildEntity(context, entity),
          ],
        ),
      ),
    );
  }

  Widget buildEntity(BuildContext context, T entity) {
    return widget._onEntitySelected != null
        ? GestureDetector(
            onTap: () => _selectEntity(entity: entity),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: widget._entityBuilder(
                    context,
                    entity,
                  ),
                ),
              ],
            ),
          )
        : Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(
              child: widget._entityBuilder(
                context,
                entity,
              ),
            ),
          ]);
  }

  Widget buildSelectableEntities(BuildContext context, List<T> entities) {
    const _wrapSpacing = 6.0;

    return Wrap(
      spacing: _wrapSpacing,
      children: [
        for (final entity in entities) buildSelectedEntity(context, entity),
      ],
    );
  }

  Widget buildSelectedEntity(BuildContext context, T entity) {
    return widget._onEntityDeselected != null
        ? GestureDetector(
            onTap: () => _deselectEntity(entity: entity),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: widget._selectedEntityBuilder(context, entity),
                ),
              ],
            ),
          )
        : Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(
              child: widget._selectedEntityBuilder(
                context,
                entity,
              ),
            ),
          ]);
  }

  Future<void> _selectEntity({required T entity}) async {
    final event = EntitySelected(entity: entity);
    widget.bloc.eventController.add(event);
  }

  Future<void> _deselectEntity({required T entity}) async {
    final event = EntityDeselected(entity: entity);
    widget.bloc.eventController.add(event);
  }
}
