import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.*;
import java.util.Properties;
import java.util.Scanner;

public class driver {
    public static void main(String[] args) throws SQLException, ClassNotFoundException {

        // is admin boolean
        boolean isAdmin = false;

        // connecting java to sql server
        Class.forName("org.postgresql.Driver");
        String url = "jdbc:postgresql://localhost:5432/";
        Properties props = new Properties();
        props.setProperty("user", "postgres");
        props.setProperty("password", "");
        Connection conn = DriverManager.getConnection(url, props);
        Statement st = conn.createStatement();
        PreparedStatement stmt;

        String command;
        Scanner input = new Scanner(System.in);
        // regex to ignore spaces inside quotes
        String regex = " (?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)";

        MessageDigest md = null;
        try {
            md = MessageDigest.getInstance("SHA-512");

        } catch (NoSuchAlgorithmException e) {
            System.out.println("Something wrong with password hashing, aborting");
            System.out.println(e.toString());
            System.exit(0);
        }

        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // login screen
        loginLoop:
        while (true) {
            System.out.println("WELCOME TO COSTA EXPRESS!");
            System.out.println("Please login or create a new account");
            System.out.println("'create' - create account");
            System.out.println("'login' - login to existing account");
            System.out.println();
            command = input.nextLine();

            // create new account
            if (command.equals("create")) {
                System.out.println("Please enter a username, password, and admin level(true, false) for new account");
                System.out.println("'user_name', 'password', 'isAdmin'");
                System.out.println();
                command = input.nextLine();
                String[] cArr = command.split(regex, -1);
                if (cArr.length == 3) {
                    try {
                        String user_name = cArr[0];
                        String passToHash = cArr[1];
                        Boolean adminStatus = Boolean.parseBoolean(cArr[2]);
                        md.update(passToHash.getBytes());
                        String hashedPass = new String(md.digest());
                        stmt = conn.prepareStatement("CALL add_user(?, ?, ?)");
                        stmt.setString(1, user_name);
                        stmt.setString(2, hashedPass);
                        stmt.setBoolean(3, adminStatus);
                        try {
                            stmt.execute();
                            System.out.println("Successfully created account. Please log in");
                            System.out.println();
                        } catch (SQLException e) {
                            System.out.println(e.toString());
                        }
                    } catch (Exception e) {
                        System.out.println("Incorrect format");
                        System.out.println(e.toString());
                    }
                } else {
                    System.out.println("Incorrect format");
                }

                // login to existing account
            } else if (command.equals("login")) {
                System.out.println("'user_name', 'password'");
                System.out.println();
                command = input.nextLine();
                String[] cArr = command.split(regex, -1);
                if (cArr.length == 2) {
                    try {
                        String user_name = cArr[0];
                        String passToHash = cArr[1];
                        md.update(passToHash.getBytes());
                        String hashedPass = new String(md.digest());

                        stmt = conn.prepareStatement("SELECT * FROM user_login(?, ?)");
                        stmt.setString(1, user_name);
                        stmt.setString(2, hashedPass);

                        try {
                            stmt.execute();
                            // if user exists, table returns 1 tuple
                            ResultSet result = stmt.getResultSet();
                            result.next();
                            if (!result.isAfterLast()) {
                                boolean login = result.getBoolean("isadmin");
                                isAdmin = login;
                                String uname = result.getString("user_name");
                                System.out.println("Successfully logged in as user - " + uname);
                                System.out.println("ADMINISTRATOR LEVEL - " + isAdmin);
                                System.out.println();
                                break loginLoop;
                            } else {
                                System.out.println("User/password incorrect try again");
                            }
                        } catch (SQLException e) {
                            System.out.println(e.toString());
                        }
                    } catch (Exception e) {
                        System.out.println("Incorrect format");
                        System.out.println(e.toString());
                    }
                } else {
                    System.out.println("Incorrect format");
                }
                // incorrect command
            } else {
                System.out.println("Incorrect command");
            }

        }

        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // input from user
        System.out.println("Type a command to execute. To view available commands, type 'list'");
        System.out.println("**Surround all multi-word inputs in double quotes**");
        while (true) {
            command = input.nextLine();
            if (command.equals("list")) {
                System.out.println("List of commands");
                System.out.println("**Surround all multi-word inputs in double quotes**");
                System.out.println("'add' - add reservation");
                System.out.println("'advanced' - commands for more advanced searches");
                System.out.println("'customer' - add/edt/view customer data");
                System.out.println("'exit' - exit program");
                System.out.println("'routesearch' - find travel between two stations (single, combination)");
                System.out.println("'ticket' - ticket a booked reservation when the passenger pays");
                System.out.println("'admin' - administrative actions");
            }
            // 1. update customer list
            else if (command.equals("customer")) {
                System.out.println("'add' - add customer");
                System.out.println("'edit' - edit existing customer data");
                System.out.println("'view' - view customer data");
                command = input.nextLine();
                // add customer
                if (command.equals("add")) {
                    System.out.println("'fName' 'lName' 'street' 'city' 'zipcode'");
                    command = input.nextLine();
                    String[] cArr = command.split(regex, -1);
                    if (cArr.length != 5) {
                        System.out.println("Incorrect format");
                    } else {
                        for (int i = 0; i < cArr.length; i++) {
                            cArr[i] = cArr[i].replaceAll("^\"|\"$", "");
                        }
                        try {
                            String fname = cArr[0];
                            String lname = cArr[1];
                            String street = cArr[2];
                            String city = cArr[3];
                            String zc = cArr[4];
                            stmt = conn.prepareStatement("SELECT insert_customer(?, ?, ?, ?, ?)");
                            stmt.setString(1, fname);
                            stmt.setString(2, lname);
                            stmt.setString(3, street);
                            stmt.setString(4, city);
                            stmt.setString(5, zc);
                            try {
                                stmt.execute();
                                ResultSet result = stmt.getResultSet();
                                result.next();
                                Integer cno = result.getInt("insert_customer");
                                System.out.println("Successfully add customer no: " + cno);
                            } catch (SQLException e) {
                                System.out.println(e.toString());
                            }
                        } catch (Exception e) {
                            System.out.println("Incorrect format");
                        }
                    }
                }
                // edit customer
                else if (command.equals("edit")) {
                    System.out.println("Provide customer no and updated attributes");
                    System.out.println("'customer_no' 'fName' 'lName' 'street' 'city' 'zipcode'");
                    command = input.nextLine();
                    String[] cArr = command.split(regex, -1);
                    if (cArr.length != 6) {
                        System.out.println("Incorrect format");
                    } else {
                        for (int i = 0; i < cArr.length; i++) {
                            cArr[i] = cArr[i].replaceAll("^\"|\"$", "");
                        }
                        try {
                            Integer cno = Integer.parseInt(cArr[0]);
                            String fname = cArr[1];
                            String lname = cArr[2];
                            String street = cArr[3];
                            String city = cArr[4];
                            String zc = cArr[5];
                            stmt = conn.prepareStatement("CALL edit_customer(?, ?, ?, ?, ?, ?)");
                            stmt.setInt(1, cno);
                            stmt.setString(2, fname);
                            stmt.setString(3, lname);
                            stmt.setString(4, street);
                            stmt.setString(5, city);
                            stmt.setString(6, zc);
                            try {
                                stmt.execute();
                                System.out.println("Success");
                            } catch (SQLException e) {
                                System.out.println(e.toString());
                            }
                        } catch (Exception e) {
                            System.out.println("Incorrect format");
                        }
                    }
                }
                //view customers
                else if (command.equals("view")) {
                    System.out.println("Provide customer no which you want to view");
                    System.out.println("'customer_no'");
                    command = input.nextLine();
                    try {
                        Integer cno = Integer.parseInt(command);
                        stmt = conn.prepareStatement("SELECT * FROM view_customer(?)");
                        stmt.setInt(1, cno);
                        try {
                            stmt.execute();
                            // resulting table will only have 1 entry due to customer no being PK
                            ResultSet result = stmt.getResultSet();
                            result.next();
                            cno = result.getInt("customer_no");
                            String fname = result.getString("fname");
                            String lname = result.getString("lname");
                            String street = result.getString("street");
                            String city = result.getString("city");
                            String zc = result.getString("zip_code");
                            System.out.println(cno + "|" + fname + "|" + lname + "|" + street + "|" + city + "|" + zc);
                            System.out.println("Success");
                        } catch (SQLException e) {
                            System.out.println(e.toString());
                        }
                    } catch (Exception e) {
                        System.out.println("Incorrect format");
                    }
                } else {
                    System.out.println("Incorrect command");
                }
            }
            //2. Find travel between two stations
            else if (command.equals("routesearch")) {
                System.out.println("'single' - single route trip search");
                System.out.println("'combination' - combination route trip search");
                System.out.println("command format:");
                System.out.println("'type' 'depart_station_no' 'dest_station_no' 'day_of_week'");
                command = input.nextLine();
                String[] cArr = command.split(regex, -1);
                if (cArr.length != 4) {
                    System.out.println("Incorrect format");
                } else {
                    try {
                        String type = cArr[0];
                        Integer dep_no = Integer.parseInt(cArr[1]);
                        Integer des_no = Integer.parseInt(cArr[2]);
                        String day = cArr[3];
                        // single route trip search
                        if (command.equals("single")) {
                            stmt = conn.prepareStatement("SELECT * FROM single_route_trip_search(?, ?, ?)");
                            stmt.setInt(1, dep_no);
                            stmt.setInt(2, des_no);
                            stmt.setString(3, day);
                            try {
                                stmt.execute();
                                // returns table full of routes, times, and stations
                                ResultSet result = stmt.getResultSet();
                                Integer route_no, arr_stop_no, price, num_stops,
                                        num_stations;
                                Time dep_time, hours_to_stop, arr_time;
                                result.next();
                                while (!result.isAfterLast()) {
                                    route_no = result.getInt(1);
                                    day = result.getString(2);
                                    dep_no = result.getInt(3);
                                    arr_stop_no = result.getInt(4);
                                    dep_time = result.getTime(5);
                                    hours_to_stop = result.getTime(6);
                                    arr_time = result.getTime(7);
                                    price = result.getInt(8);
                                    num_stops = result.getInt(9);
                                    num_stations = result.getInt(10);
                                    System.out.println(route_no + "|" + day + "|" + dep_no + "|" + arr_stop_no + "|"
                                            + dep_time
                                            + "|" + hours_to_stop + "|" + arr_time + "|" + price + "|" + num_stops + "|"
                                            + num_stations);
                                    result.next();
                                }
                                System.out.println("Success");
                            } catch (SQLException e) {
                                System.out.println(e.toString());
                            }
                        }
                        // combination route trip search
                        else if (command.equals("combination")) {
                            stmt = conn.prepareStatement("SELECT * FROM interchange_route(?, ?, ?)");
                            stmt.setInt(1, dep_no);
                            stmt.setInt(2, des_no);
                            stmt.setString(3, day);
                            try {
                                stmt.execute();
                                // returns table full of routes, times, stations, prices, etc
                                ResultSet result = stmt.getResultSet();
                                Integer route_one, route_two, stop_one, inter_stop, stop_two,
                                        price_first_leg, num_stops, price_sec_leg, total_price, num_stations,
                                        num_stations_first, num_stops_first, num_stations_two, num_stops_two;
                                Time dep_time_one, dep_time_two, time_to_inter, time_to_final, total_time,
                                        inter_arr, final_arr;
                                result.next();
                                while (!result.isAfterLast()) {
                                    route_one = result.getInt(2);
                                    route_two = result.getInt(3);
                                    stop_one = result.getInt(4);
                                    inter_stop = result.getInt(7);
                                    stop_two = result.getInt(11);
                                    price_first_leg = result.getInt(8);
                                    num_stops = result.getInt(19);
                                    price_sec_leg = result.getInt(12);
                                    total_price = result.getInt(13);
                                    num_stations = result.getInt(20);
                                    num_stations_first = result.getInt(16);
                                    num_stops_first = result.getInt(15);
                                    num_stations_two = result.getInt(18);
                                    num_stops_two = result.getInt(17);
                                    dep_time_one = result.getTime(5);
                                    dep_time_two = result.getTime(9);
                                    time_to_inter = result.getTime(6);
                                    time_to_final = result.getTime(10);
                                    total_time = result.getTime(14);
                                    inter_arr = result.getTime(21);
                                    final_arr = result.getTime(22);
                                    day = result.getString(1);
                                    System.out.println(day + "|" + route_one + "|" + route_two
                                            + "|" + stop_one + "|" + dep_time_one + "|" + time_to_inter
                                            + "|" + inter_stop + "|" + inter_arr + "|" + price_first_leg + "|"
                                            + dep_time_two
                                            + "|" + time_to_final + "|" + stop_two + "|" + price_sec_leg
                                            + "|" + total_price + "|" + total_time + "|"
                                            + num_stops_first
                                            + "|" + num_stations_first + "|" + num_stops_two + "|"
                                            + num_stations_two + "|" + num_stops + "|" + num_stations
                                            + "|" + final_arr);
                                    result.next();
                                }
                                System.out.println("Success");
                            } catch (SQLException e) {
                                System.out.println(e.toString());
                            }
                        } else {
                            System.out.println("Incorrect command");
                        }
                    } catch (Exception e) {
                        System.out.println("Incorrect format");
                    }
                }
            }
            //3. Add Reservation
            else if (command.equals("add")) {
                System.out.println("Book a reservation");
                System.out.println("'customer_no' 'dep_no' 'arrival' 'route' 'day' 'time' 'ifSubstition'");
                command = input.nextLine();
                String[] cArr = command.split(regex, -1);
                if (cArr.length != 7) {
                    System.out.println("Incorrect format");
                } else {
                    for (int i = 0; i < cArr.length; i++) {
                        cArr[i] = cArr[i].replaceAll("^\"|\"$", "");
                    }
                    try {
                        Integer c_no = Integer.parseInt(cArr[0]);
                        Integer dep_no = Integer.parseInt(cArr[1]);
                        Integer arr_no = Integer.parseInt(cArr[2]);
                        Integer route = Integer.parseInt(cArr[3]);
                        String day = cArr[4];
                        Time time = java.sql.Time.valueOf(cArr[5]);
                        Boolean sub = Boolean.parseBoolean((cArr[6]));

                        stmt = conn.prepareStatement("CALL book_trip(?, ?, ?, ?, ?, ?, ?)");
                        stmt.setInt(1, c_no);
                        stmt.setInt(2, dep_no);
                        stmt.setInt(3, arr_no);
                        stmt.setInt(4, route);
                        stmt.setString(5, day);
                        stmt.setTime(6, time);
                        stmt.setBoolean(7, sub);
                        try {
                            stmt.execute();
                            System.out.println("Success");
                        } catch (SQLException e) {
                            System.out.println(e.toString());
                        }
                    } catch (Exception e) {
                        System.out.println("Incorrect format");
                    }
                }
            }
            // 4. ticket a booked reservation
            else if (command.equals("ticket")) {
                System.out.println("Enter the reservation no");
                System.out.println("'resv_no'");
                command = input.nextLine();
                try {
                    Integer resv_no = Integer.parseInt(command);
                    stmt = conn.prepareStatement("CALL paid_ticket(?)");
                    stmt.setInt(1, resv_no);
                    try {
                        stmt.execute();
                        System.out.println("Success");
                    } catch (SQLException e) {
                        System.out.println(e.toString());
                    }
                } catch (Exception e) {
                    System.out.println("Incorrect format");
                }
            }
            // 5. Advanced searches
            else if (command.equals("advanced")) {
                System.out.println(
                        "'a' - Find all trains that pass through a specific station at a day/time combination");
                System.out.println("'b' - Find the routes that travel more than one rail line");
                System.out.println("'c' - Rank the trains that are scheduled for more than one route");
                System.out
                        .println("'d' - Find routes that pass through the same stations but don't have the same stops");
                System.out.println("'e' - Find any stations through which all trains pass through");
                System.out.println("'f' - Find all the trians that do not stop at a specific station");
                System.out.println("'g' - Find routes that stop at least at XX% opf the stations they visit");
                System.out.println("'h' - Display the schedule of a route");
                System.out.println("'i' - Find the availability of a route at every stop on a specific day/time");
                command = input.nextLine();
                // 5a.
                if (command.equals("a")) {
                    System.out.println("'station_no' 'day' 'time'");
                    command = input.nextLine();
                    String[] cArr = command.split(regex, -1);
                    if (cArr.length != 3) {
                        System.out.println("Incorrect format");
                    } else {
                        try {
                            int s_no = Integer.parseInt(cArr[0]);
                            String day = cArr[1];
                            Time time = java.sql.Time.valueOf(cArr[2]);
                            stmt = conn.prepareStatement("SELECT * FROM station_time_search(?, ?, ?)");
                            stmt.setInt(1, s_no);
                            stmt.setString(2, day);
                            stmt.setTime(3, time);
                            try {
                                stmt.execute();
                                // returns table full of trains
                                ResultSet result = stmt.getResultSet();
                                Integer train_no;
                                result.next();
                                System.out.println("Available trains:");
                                while (!result.isAfterLast()) {
                                    train_no = result.getInt(1);
                                    System.out.println(train_no);
                                    result.next();
                                }
                                System.out.println("Success");
                            } catch (SQLException e) {
                                System.out.println(e.toString());
                            }
                        } catch (Exception e) {
                            System.out.println("Incorrect format");
                        }
                    }
                }
                // 5b.
                else if (command.equals("b")) {
                    stmt = conn.prepareStatement("SELECT * FROM routes_mlines()");
                    try {
                        stmt.execute();
                        // returns table
                        ResultSet result = stmt.getResultSet();
                        int r_no, rank;
                        result.next();
                        int num = 10;
                        System.out
                                .println("Routes that travel more than one rail line " + (num - 9) + "-" + num
                                        + ":");
                        for (int i = 0; i < 10; i++) {
                            if (result.isAfterLast()) {
                                System.out.println("End of list");
                                break;
                            }
                            r_no = result.getInt(1);
                            rank = result.getInt(2);
                            System.out.println("r_no=" + r_no + "|" + "rank=" + rank);
                            result.next();
                        }
                        num += 10;
                        while (true) {
                            System.out.println("'next' - view next 10 entires");
                            System.out.println("'exit' - leave");
                            command = input.nextLine();
                            if (command.equals("next")) {
                                System.out
                                        .println("Routes that travel more than one rail line " + (num - 9) + "-" + num
                                                + ":");
                                for (int i = 0; i < 10; i++) {
                                    if (result.isAfterLast()) {
                                        System.out.println("End of list");
                                        break;
                                    }
                                    r_no = result.getInt(1);
                                    rank = result.getInt(2);
                                    System.out.println("r_no=" + r_no + "|" + "rank=" + rank);
                                    result.next();
                                }
                                num += 10;
                            } else {
                                break;
                            }
                        }
                        System.out.println("Success");
                    } catch (SQLException e) {
                        System.out.println(e.toString());
                    }
                    // 5c.
                } else if (command.equals("c")) {
                    stmt = conn.prepareStatement("SELECT * FROM rank_trains_mroutes()");
                    try {
                        stmt.execute();
                        // returns table
                        ResultSet result = stmt.getResultSet();
                        int train_no, total_routes, rank;
                        result.next();
                        int num = 10;
                        System.out
                                .println("Trains that are schedule for more than 1 route " + (num - 9) + "-" + num
                                        + ":");
                        System.out.println("train_no|total_routes|rank");
                        for (int i = 0; i < 10; i++) {
                            if (result.isAfterLast()) {
                                System.out.println("End of list");
                                break;
                            }
                            train_no = result.getInt(1);
                            total_routes = result.getInt(2);
                            rank = result.getInt(3);
                            System.out.println(train_no + "|" + total_routes + "|" + rank);
                            result.next();
                        }
                        num += 10;
                        while (true) {
                            System.out.println("'next' - view next 10 entires");
                            System.out.println("'exit' - leave");
                            command = input.nextLine();
                            if (command.equals("next")) {
                                System.out
                                        .println("Routes that travel more than one rail line " + (num - 9) + "-" + num
                                                + ":");
                                for (int i = 0; i < 10; i++) {
                                    if (result.isAfterLast()) {
                                        System.out.println("End of list");
                                        break;
                                    }
                                    train_no = result.getInt(1);
                                    total_routes = result.getInt(2);
                                    rank = result.getInt(3);
                                    System.out.println(train_no + "|" + total_routes + "|" + rank);
                                    result.next();
                                }
                                num += 10;
                            } else {
                                break;
                            }
                        }
                        System.out.println("Success");
                    } catch (SQLException e) {
                        System.out.println(e.toString());
                    }
                }
                // 5. d
                else if (command.equals("d")) {
                    try {
                        stmt = conn.prepareStatement("SELECT * FROM routes_same_stations()");
                        stmt.execute();

                        ResultSet result = stmt.getResultSet();

                        int route_no;

                        result.next();
                        System.out.println(
                                "Routes that pass through the same stations but don't have the same stops: \n");
                        while (!result.isAfterLast()) {
                            route_no = result.getInt(1);
                            System.out.println(route_no);
                            result.next();
                        }
                        System.out.println("Success");
                    } catch (SQLException e) {
                        System.out.println(e.toString());
                    }
                }
                // 5. e
                else if (command.equals("e")) {
                    stmt = conn.prepareStatement("SELECT * FROM stations_all_trains()");
                    try {
                        stmt.execute();
                        // returns table
                        ResultSet result = stmt.getResultSet();
                        int s_no;
                        result.next();
                        System.out.println("Stations which all trains pass through:");
                        while (!result.isAfterLast()) {
                            s_no = result.getInt(1);
                            System.out.println(s_no);
                            result.next();
                        }
                        System.out.println("Success");
                    } catch (SQLException e) {
                        System.out.println(e.toString());
                    }
                }
                //5. f
                else if (command.equals("f")) {
                    System.out.println("'station_no'");
                    command = input.nextLine();
                    try {
                        int s_no = Integer.parseInt(command);
                        stmt = conn.prepareStatement("SELECT * FROM does_not_stop_at(?)");
                        stmt.setInt(1, s_no);
                        try {
                            stmt.execute();
                            // returns table
                            ResultSet result = stmt.getResultSet();
                            int train_no;
                            String train_name;
                            result.next();
                            int num = 10;
                            System.out
                                    .println("Trains that do not stop at station: " + s_no + " " + (num - 9) + "-" + num
                                            + ":");
                            for (int i = 0; i < 10; i++) {
                                if (result.isAfterLast()) {
                                    System.out.println("End of list");
                                    break;
                                }
                                train_no = result.getInt(1);
                                train_name = result.getString(2);
                                System.out.println(train_no + "|" + train_name);
                                result.next();
                            }
                            num += 10;
                            while (true) {
                                System.out.println("'next' - view next 10 entires");
                                System.out.println("'exit' - leave");
                                command = input.nextLine();
                                if (command.equals("next")) {
                                    System.out
                                            .println("Trains that do not stop at station - " + s_no + " " + (num - 9)
                                                    + "-" + num
                                                    + ":");
                                    for (int i = 0; i < 10; i++) {
                                        if (result.isAfterLast()) {
                                            System.out.println("End of list");
                                            break;
                                        }
                                        train_no = result.getInt(1);
                                        train_name = result.getString(2);
                                        System.out.println(train_no + "|" + train_name);
                                        result.next();
                                    }
                                    num += 10;
                                } else {
                                    break;
                                }
                            }
                            System.out.println("Success");
                        } catch (SQLException e) {
                            System.out.println(e.toString());
                        }
                    } catch (Exception e) {
                        System.out.println("Incorrect format");
                    }
                }
                // 5. g Find routes that stop @ at least @ XX% of the stations they visit
                else if (command.equals("g")) {
                    System.out.println("'percent'\n***DO NOT INCLUDE '%'");
                    command = input.nextLine();
                    try {
                        int percent = Integer.parseInt(command);
                        stmt = conn.prepareStatement("SELECT * FROM routes_percent_gt(?)");
                        stmt.setInt(1, percent);
                        stmt.execute();

                        ResultSet result = stmt.getResultSet();

                        int route_no;
                        String per;

                        result.next();
                        System.out.println(
                                "Routes that stop at at least " + percent + "% of the stations they visit: \n");
                        while (!result.isAfterLast()) {
                            route_no = result.getInt(1);
                            per = result.getString(2);
                            System.out.println(route_no + "|" + per);
                            result.next();
                        }
                        System.out.println("Success");
                    } catch (SQLException e) {
                        System.out.println(e.toString());
                    }
                }
                // 5. h display schedule of route
                else if (command.equals("h")) {
                    System.out.println("'route_no'");
                    command = input.nextLine();
                    try {
                        int r_no = Integer.parseInt(command);
                        stmt = conn.prepareStatement("SELECT * FROM disp_schedule_route(?)");
                        stmt.setInt(1, r_no);
                        try {
                            stmt.execute();
                            // returns table
                            ResultSet result = stmt.getResultSet();
                            String day, time;
                            int train_no;
                            result.next();
                            System.out.println("Schedule of route - " + r_no);
                            System.out.println("day|time|train_no");
                            while (!result.isAfterLast()) {
                                day = result.getString(1);
                                time = result.getTime(2).toString();
                                train_no = result.getInt(3);
                                System.out.println(day + "|" + time + "|" + train_no);
                                result.next();
                            }
                            System.out.println("Success");
                        } catch (SQLException e) {
                            System.out.println(e.toString());
                        }
                    } catch (Exception e) {
                        System.out.println("Incorrect format");
                    }
                }
                // 5. i find the availability of a route at every stop on a specific day and time
                else if (command.equals("i")) {
                    System.out.println("'day' 'time'");
                    command = input.nextLine();
                    String[] cArr = command.split(regex, -1);
                    if (cArr.length != 2) {
                        System.out.println("Incorrect format");
                        break;
                    }
                    try {
                        String day = cArr[0];
                        Time timeT = java.sql.Time.valueOf(cArr[1]);
                        stmt = conn.prepareStatement("SELECT * FROM route_avail(?, ?)");
                        stmt.setString(1, day);
                        stmt.setTime(2, timeT);
                        try {
                            stmt.execute();

                            // returns table
                            ResultSet result = stmt.getResultSet();
                            int r_no, train_no, stop_no, seats_open;
                            String dayQ, time;

                            result.next();
                            int num = 10;
                            System.out
                                    .println(
                                            "Routes available for day - " + day + "& time -" + timeT + " : " + (num - 9)
                                                    + "-" + num);
                            System.out.println("route_no|day|depart time|train_no|stop_no|seats_open");
                            for (int i = 0; i < 10; i++) {
                                if (result.isAfterLast()) {
                                    System.out.println("End of list");
                                    break;
                                }
                                r_no = result.getInt(1);
                                dayQ = result.getString(2);
                                time = result.getString(3).toString();
                                train_no = result.getInt(4);
                                stop_no = result.getInt(5);
                                seats_open = result.getInt(6);
                                System.out.println(r_no + "|" + dayQ + "|" + time + "|" + train_no + "|" + stop_no + "|"
                                        + seats_open);
                                result.next();
                            }
                            num += 10;
                            while (true) {
                                System.out.println("'next' - view next 10 entires");
                                System.out.println("'exit' - leave");
                                command = input.nextLine();
                                if (command.equals("next")) {
                                    System.out
                                            .println(
                                                    "Routes available for day - " + day + "& time -" + timeT + " : "
                                                            + (num - 9)
                                                            + "-" + num);
                                    System.out.println("route_no|day|depart time|train_no|stop_no|seats_open");
                                    for (int i = 0; i < 10; i++) {
                                        if (result.isAfterLast()) {
                                            System.out.println("End of list");
                                            break;
                                        }
                                        r_no = result.getInt(1);
                                        dayQ = result.getString(2);
                                        time = result.getString(3).toString();
                                        train_no = result.getInt(4);
                                        stop_no = result.getInt(5);
                                        seats_open = result.getInt(6);
                                        System.out.println(
                                                r_no + "|" + dayQ + "|" + time + "|" + train_no + "|" + stop_no + "|"
                                                        + seats_open);
                                        result.next();
                                    }
                                    num += 10;
                                } else {
                                    break;
                                }
                            }
                            System.out.println("Success");
                        } catch (SQLException e) {
                            System.out.println(e.toString());
                        }

                    } catch (Exception e) {
                        System.out.println("Incorrect format");
                    }
                } else {
                    System.out.println("Incorrect command");
                }
            }
            // shutting down program
            else if (command.equals("exit")) {
                break;
            }
            // administrator commands
            else if (command.equals("admin")) {
                if (isAdmin) {
                    System.out.println("'import' - import data into database");
                    System.out.println("'export' - export data into database");
                    System.out.println("'delete' - delete data into database");
                    command = input.nextLine();
                    if (command.equals("import")) {

                    } else if (command.equals("export")) {

                    } else if (command.equals("delete")) {
                        System.out.println("ARE YOU SURE YOU WANT TO DELETE DATABASE?");
                        System.out.println("TYPE 'YES' IF SURE, OTHERWISE PRESS ENTER");
                        command = input.nextLine();
                        if (command.equals("YES")) {
                            System.out.println("DELETING...");
                            stmt = conn.prepareStatement("CALL delete_db()");
                            try {
                                stmt.execute();
                            } catch (SQLException e) {
                                System.out.println(e.toString());
                            }
                            System.out.println("Successfully deleted database");
                        } else {
                            System.out.println("Aborting delete...");
                        }
                    } else {
                        System.out.println("Incorrect command");
                    }
                } else {
                    System.out.println("Access denied");
                }
            } else {
                System.out.println("Incorrect command");
                System.out.println("Type a command to execute. To view available commands, type 'list'");
            }
            System.out.println();
        }
        System.out.println("Exiting program");
        input.close();
    }
}
