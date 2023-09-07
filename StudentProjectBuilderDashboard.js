import React from "react";
import Header from "./Header";
import Footer from "./Footer";
import SideBar from "./SideBar";
import { Outlet } from "react-router-dom";
// this file acts as the parent and imports all the following code down below to create the student builder dashboard
// route/routes is used with OUTLET to bring in different content the content is called in the side bar folder
export default function StudentProjectBuilderDashboard() {
  return (
    <div>
      <Header></Header>
      <div style={{ display: "flex", flexDirection: "row" }}>
        <div style={{ display: "flex", height: "calc(100vh - 90px)" }}>
          <SideBar />
        </div>
        {/* this css here allows the page width to change dynamically when minimizing the side bar */}
        <main
          style={{
            flexGrow: "1",
            display: "flex",
            flexDirection: "column",
          }}
        >
          <Outlet />
        </main>
      </div>
      <Footer style={{ display: "flex", justifyContent: "flex-end" }}></Footer>
    </div>
  );
}
