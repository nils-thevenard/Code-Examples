export default function Quiz() {
  return (
    //inline css was used here to simplify the file structure and as it is the same for each content component
    <div // body
      style={{
        display: "flex",
        alignItems: "center",
        justifyContent: " center",
        backgroundColor: "#b2e4fa",
        height: "calc(100vh - 90px)",
      }}
    >
      <div // frame
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          width: "95%",
          height: "90%",
          backgroundColor: "#d9f2fd",
          borderRadius: "30px",
        }}
      >
        Take the QUIZ {/* place holder */}
        <div // content
          style={{
            display: "flex",
            width: "80%",
          }}
        ></div>
      </div>
    </div>
  );
}
