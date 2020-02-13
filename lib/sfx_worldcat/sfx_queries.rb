module SFXWorldcat
  ## Date format yyyy-mm-dd ('2017-12-05);
  ## different tables have different update dates
  ## so multiple queries must be made
  def changed_object_title_query(date)
    %(
      SELECT KB_OBJECTS.object_id
      FROM KB_OBJECTS
        JOIN KB_TITLE
          ON KB_OBJECTS.object_id = KB_TITLE.object_id
      WHERE KB_OBJECTS.last_update_date > \'#{date}\'
      OR KB_TITLE.last_update_date > \'#{date}\'
      GROUP BY KB_OBJECTS.object_id
    )
  end

  def changed_local_title_query(date)
    %(
      SELECT KB_OBJECTS.object_id
      FROM KB_OBJECTS
        JOIN KB_TITLE
          ON KB_OBJECTS.object_id = KB_TITLE.object_id
        JOIN `#{SFX_LOCAL_DATABASE}`.LCL_TITLE
          ON KB_TITLE.title_id = `#{SFX_LOCAL_DATABASE}`.LCL_TITLE.title_id
      WHERE `#{SFX_LOCAL_DATABASE}`.LCL_TITLE.last_update_date > \'#{date}\'
      GROUP BY KB_OBJECTS.object_id
    )
  end

  def changed_author_query(date)
    %(
      SELECT KB_OBJECTS.object_id
      FROM KB_OBJECTS
        JOIN KB_AUTHORS
          ON KB_OBJECTS.object_id = KB_AUTHORS.object_id
      WHERE KB_AUTHORS.last_update_date > \'#{date}\'
      GROUP BY KB_OBJECTS.object_id
    )
  end

  def changed_publisher_query(date)
    %(
      SELECT KB_OBJECTS.object_id
      FROM KB_OBJECTS
        JOIN KB_PUBLISHERS
          ON KB_OBJECTS.object_id = KB_PUBLISHERS.object_id
      WHERE KB_PUBLISHERS.last_update_date > \'#{date}\'
      GROUP BY KB_OBJECTS.object_id
    )
  end

  def changed_identifier_query(date)
    %(
      SELECT KB_OBJECTS.object_id
      FROM KB_OBJECTS
        JOIN KB_OBJECT_IDENTIFIERS
          ON KB_OBJECTS.object_id = KB_OBJECT_IDENTIFIERS.object_id
      WHERE KB_OBJECT_IDENTIFIERS.last_update_date > \'#{date}\'
      GROUP BY KB_OBJECTS.object_id
    )
  end

  def changed_local_identifier_query(date)
    %(
      SELECT KB_OBJECTS.object_id
      FROM KB_OBJECTS
        JOIN `#{SFX_LOCAL_DATABASE}`.LCL_OBJECT_IDENTIFIERS
          ON KB_OBJECTS.object_id = `#{SFX_LOCAL_DATABASE}`.LCL_OBJECT_IDENTIFIERS.object_id
      WHERE `#{SFX_LOCAL_DATABASE}`.LCL_OBJECT_IDENTIFIERS.last_update_date > \'#{date}\'
      GROUP BY KB_OBJECTS.object_id
    )
  end

  def changed_relations_query(date)
    %(
      SELECT KB_OBJECTS.object_id
      FROM KB_OBJECTS
        JOIN KB_RELATIONS
          ON KB_OBJECTS.object_id = KB_RELATIONS.primary_object_id
      WHERE KB_RELATIONS.last_update_date > \'#{date}\'
      GROUP BY KB_OBJECTS.object_id
    )
  end

  def unwanted_object_query
    %(
      SELECT KB_OBJECTS.object_id
      FROM KB_OBJECT_PORTFOLIOS
        JOIN KB_TARGET_SERVICES
          ON KB_OBJECT_PORTFOLIOS.target_service_id = KB_TARGET_SERVICES.target_service_id
        JOIN KB_TARGETS
          ON KB_TARGET_SERVICES.target_id = KB_TARGETS.target_id
        JOIN KB_OBJECTS
          ON KB_OBJECT_PORTFOLIOS.object_id = KB_OBJECTS.object_id
        JOIN KB_TITLE
          ON KB_OBJECTS.object_id = KB_TITLE.object_id
        JOIN `#{SFX_LOCAL_DATABASE}`.LCL_OBJECT_PORTFOLIO_INVENTORY
          ON KB_OBJECT_PORTFOLIOS.op_id = `#{SFX_LOCAL_DATABASE}`.LCL_OBJECT_PORTFOLIO_INVENTORY.op_id
        JOIN `#{SFX_LOCAL_DATABASE}`.LCL_SERVICE_INVENTORY
          ON KB_TARGET_SERVICES.target_service_id = `#{SFX_LOCAL_DATABASE}`.LCL_SERVICE_INVENTORY.target_service_id
      WHERE
        service_type = 'getFullTxt'
        and KB_TARGET_SERVICES.STATUS = 'ACTIVE'
        and KB_OBJECT_PORTFOLIOS.STATUS = 'ACTIVE'
        and LCL_OBJECT_PORTFOLIO_INVENTORY.ACTIVATION_STATUS = 'ACTIVE'
        and LCL_SERVICE_INVENTORY.ACTIVATION_STATUS = 'ACTIVE'
        and LCL_SERVICE_INVENTORY.available_for = 'r.01PRI.sfxlcl41'
        and KB_TARGETS.target_id IN (1000000000000645)
      GROUP BY KB_OBJECTS.object_id
    )
  end

  def object_id_query
    %(
      SELECT KB_OBJECTS.object_id
      FROM KB_OBJECT_PORTFOLIOS
        JOIN KB_TARGET_SERVICES
          ON KB_OBJECT_PORTFOLIOS.target_service_id = KB_TARGET_SERVICES.target_service_id
        JOIN KB_TARGETS
          ON KB_TARGET_SERVICES.target_id = KB_TARGETS.target_id
        JOIN KB_OBJECTS
          ON KB_OBJECT_PORTFOLIOS.object_id = KB_OBJECTS.object_id
        JOIN KB_TITLE
          ON KB_OBJECTS.object_id = KB_TITLE.object_id
        JOIN `#{SFX_LOCAL_DATABASE}`.LCL_OBJECT_PORTFOLIO_INVENTORY
          ON KB_OBJECT_PORTFOLIOS.op_id = `#{SFX_LOCAL_DATABASE}`.LCL_OBJECT_PORTFOLIO_INVENTORY.op_id
        JOIN `#{SFX_LOCAL_DATABASE}`.LCL_SERVICE_INVENTORY
          ON KB_TARGET_SERVICES.target_service_id = `#{SFX_LOCAL_DATABASE}`.LCL_SERVICE_INVENTORY.target_service_id
      WHERE
        service_type = 'getFullTxt'
        and KB_TARGET_SERVICES.STATUS = 'ACTIVE'
        and KB_OBJECT_PORTFOLIOS.STATUS = 'ACTIVE'
        and LCL_OBJECT_PORTFOLIO_INVENTORY.ACTIVATION_STATUS = 'ACTIVE'
        and LCL_SERVICE_INVENTORY.ACTIVATION_STATUS = 'ACTIVE'
        and LCL_SERVICE_INVENTORY.available_for = 'r.01PRI.sfxlcl41'
        and object_type in ('JOURNAL', 'NEWSPAPER', 'CONFERENCE', 'TRANSCRIPT', 'WIRE', 'SERIES')
        and KB_TARGETS.target_id NOT IN (#{unwanted_target_ids.join(',')})
      GROUP BY KB_OBJECTS.object_id
    )
  end

  def title_query(object_id)
    %(
      SELECT
        KB_TITLE.title_value,
        KB_TITLE.non_filing_char,
        title_type,
        title_sub_type,
        title_language,
        LCL_TITLE.title_value local_title,
        LCL_TITLE.non_filing_char local_non_filing
      FROM KB_TITLE
        LEFT JOIN `#{SFX_LOCAL_DATABASE}`.LCL_TITLE
          ON KB_TITLE.title_id = LCL_TITLE.title_id
      WHERE KB_TITLE.object_id = #{object_id}
      AND KB_TITLE.status = 'ACTIVE'
    )
  end

  def author_query(object_id)
    %(
      SELECT
        full_name,
        full_name_format,
        author_type,
        author_significance,
        author_id
      FROM KB_AUTHORS
      WHERE
        object_id = #{object_id}
        AND author_significance IN ('MAIN', 'ADDITIONAL')
        AND author_type IS NOT NULL
    )
  end

  def publisher_query(object_id)
    %(
      SELECT
        publisher_name_display,
        date_of_publication,
        place_of_publication_display
      FROM KB_PUBLISHERS
      WHERE object_id = #{object_id}
      GROUP BY
        publisher_name_display,
        date_of_publication,
        place_of_publication_display
    )
  end

  def target_name_query(object_id)
    %(
      SELECT target_name
      FROM KB_OBJECT_PORTFOLIOS
        JOIN KB_TARGET_SERVICES
          ON KB_OBJECT_PORTFOLIOS.target_service_id = KB_TARGET_SERVICES.target_service_id
        JOIN KB_TARGETS
          ON KB_TARGET_SERVICES.target_id = KB_TARGETS.target_id
      WHERE KB_OBJECT_PORTFOLIOS.object_id = #{object_id}
      AND KB_TARGET_SERVICES.STATUS = 'ACTIVE'
      GROUP BY target_name
    )
  end

  def language_query(object_id)
    %(
      SELECT language
      FROM KB_OBJECTS
      WHERE object_id = #{object_id}
    )
  end

  def related_object_query(object_id)
    %(
      SELECT
        secondary_object_id,
        relation_type,
        language
      FROM KB_RELATIONS
        JOIN KB_OBJECTS
          ON KB_RELATIONS.secondary_object_id = KB_OBJECTS.object_id
      WHERE primary_object_id = #{object_id}
    )
  end

  def identifier_query(object_id)
    %(
      SELECT
        type,
        sub_type,
        value
      FROM KB_OBJECT_IDENTIFIERS
      WHERE
        object_id = #{object_id}
        and status = 'ACTIVE'
    )
  end

  def local_identifier_query(object_id)
    %(
      SELECT
        value
      FROM `#{SFX_LOCAL_DATABASE}`.LCL_OBJECT_IDENTIFIERS
      WHERE
        object_id = #{object_id}
        AND LOWER(value) LIKE 'oclc%'
    )
  end

  def local_brief_object_query
    %(
      SELECT object_id
      FROM `#{SFX_LOCAL_DATABASE}`.LCL_OBJECT_IDENTIFIERS
      WHERE
        LOWER(value) = 'brief'
    )
  end
  
  def local_skip_object_query
    %(
      SELECT object_id
      FROM `#{SFX_LOCAL_DATABASE}`.LCL_OBJECT_IDENTIFIERS
      WHERE
        LOWER(value) = 'skip'
    )
  end

  def local_object_query
    %(
      SELECT object_id
      FROM `#{SFX_LOCAL_DATABASE}`.LCL_OBJECT_IDENTIFIERS
      WHERE
        LOWER(value) LIKE 'oclc%'
    )
  end
end
