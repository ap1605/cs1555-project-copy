create or replace function speed_of_train(int, int) RETURNS FLOAT
AS $$
DECLARE
    train INT := $1;
    line INT := $2;
    max_speed INT := 0;
    sc speed_compare%ROWTYPE;
    curs_sot cursor FOR SELECT * FROM speed_compare;
BEGIN
    OPEN curs_sot;

    LOOP
        FETCH curs_sot INTO sc;
        IF sc IS NULL
        THEN
            EXIT;
        end if;
        IF sc.train_no = train AND sc.line_no = line
        THEN
            EXIT;
        end if;
    end LOOP;
    IF(SC.top_speed > sc.speed_limit)
    THEN
        max_speed := SC.speed_limit;
    ELSE
        max_speed := SC.top_speed;
    end if;
    CLOSE curs_sot;
    IF(sc is NULL) THEN RAISE 'bad_data' USING errcode='MYERR';
    else RETURN max_speed;
    end if;
    EXCEPTION
        WHEN sqlstate 'MYERR' then
            RAISE notice 'INVALID_RTORLN_ERROR: TRAIN:%, LINE:%', $1, $2;
end $$ LANGUAGE plpgsql;

--SELECT speed_of_train(337, 1);
