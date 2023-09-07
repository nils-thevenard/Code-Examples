import React from "react";
//inline css used to make one folder that takes care of the whole footer
export default function Footer() {
  return (
    <div
      style={{
        display: "flex",
        justifyContent: "center",
        backgroundColor: "white",
        height: "45px",
      }}
    >
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          color: "#6c6c6c",
        }}
      >
        © LevelUp Works 2020
      </div>
    </div>
  );
}
