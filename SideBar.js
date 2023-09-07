import React from "react";
import { useState, useEffect } from "react";
import { Link } from "react-router-dom";
// importing css styles and images for both selected and unselected
import styles from "./SideBar.module.css";
import learningObjectives from "./StudentDashboardIMG/learningObjectives.png";
import instructions from "./StudentDashboardIMG/instructions.png";
import video from "./StudentDashboardIMG/video.png";
import makeProject from "./StudentDashboardIMG/makeProject.png";
import submitProject from "./StudentDashboardIMG/submitProject.png";
import bonusChallenge from "./StudentDashboardIMG/bonusChallenge.png";
import takeTheQuiz from "./StudentDashboardIMG/takeTheQuiz.png";
import learningObjectivesSelected from "./StudentDashboardIMG/learningObjectivesSelected.png";
import instructionsSelected from "./StudentDashboardIMG/instructionsSelected.png";
import videoSelected from "./StudentDashboardIMG/videoSelected.png";
import makeProjectSelected from "./StudentDashboardIMG/makeProjectSelected.png";
import submitProjectSelected from "./StudentDashboardIMG/submitProjectSelected.png";
import bonusChallengeSelected from "./StudentDashboardIMG/bonusChallenge.png"; //missing selected file
import takeTheQuizSelected from "./StudentDashboardIMG/takeTheQuiz.png"; //missing selected file
import arrowLeft from "./StudentDashboardIMG/arrowLeft.png";
import signOut from "./Images/Icon awesome-sign-out-alt@2x.png";
import profile from "./Images/Icon awesome-user-circle@2x.png";
import settings from "./Images/Icon material-settings@2x.png";

//function to toggle side bar css when the arrow is clicked.
//this function is referenced often in the code to allow the different styling to change with the nav bar
function SideBar() {
  const [displayIcons, setDisplayIcons] = useState(true);
  const toggle = () => setDisplayIcons(!displayIcons);
  const [selectIcons, setSelectIcons] = useState(null);

  // The button content is stored in an array and displayed using maps. this allows for much less code and makes it easier to work with
  const sideIcons = [
    {
      routes: "/StudentProjectBuilderDashboard/learningObjectives",
      icon: <img src={learningObjectives} alt="" />,
      iconSelected: <img src={learningObjectivesSelected} alt="" />,
      name: "LEARNING OBJECTIVES",
    },
    {
      routes: "/StudentProjectBuilderDashboard/instructions",
      icon: <img src={instructions} alt="" />,
      iconSelected: <img src={instructionsSelected} alt="" />,
      name: "INSTRUCTIONS",
    },
    {
      routes: "/StudentProjectBuilderDashboard/videoTutorial",
      icon: <img src={video} alt="" />,
      iconSelected: <img src={videoSelected} alt="" />,
      name: "VIDEO TUTORIAL",
    },
    {
      routes: "/StudentProjectBuilderDashboard/makeProject",
      icon: <img src={makeProject} alt="" />,
      iconSelected: <img src={makeProjectSelected} alt="" />,
      name: "MAKE PROJECT",
    },
    {
      routes: "/StudentProjectBuilderDashboard/submitProject",
      icon: <img src={submitProject} alt="" />,
      iconSelected: <img src={submitProjectSelected} alt="" />,
      name: "SUBMIT PROJECT",
    },
    {
      routes: "/StudentProjectBuilderDashboard/bonusChallenge",
      icon: <img src={bonusChallenge} alt="" />,
      iconSelected: <img src={bonusChallengeSelected} alt="" />,
      name: "BONUS CHALLENGE",
    },
    {
      routes: "/StudentProjectBuilderDashboard/takeTheQuiz",
      icon: <img src={takeTheQuiz} alt="" />,
      iconSelected: <img src={takeTheQuizSelected} alt="" />,
      name: "TAKE THE QUIZ",
    },
  ];

  // fetch request for the student profile pic
  const [results, setResults] = useState([]);
  useEffect(() => {
    fetch("http://localhost:4000/api/students")
      .then((res) => res.json())
      .then((data) => setResults(data)); //fetch takes a while to execute relative to the rest of the code which is why is square brackets
  }, []);

  return (
    <div style={{ height: "100%" }}>
      <div
        className={styles.body}
        style={{
          //ternary operator works based on the responsive value
          width: displayIcons ? "200px" : "77px", //first position = true
        }}
      >
        {/*displaying the profile pic ======================================== */}
        <div>
          {results &&
            results.map(function (result) {
              return (
                <div key={result.id}>
                  <img
                    className={styles.profilePic}
                    src={result.profile_pic}
                    style={{ display: displayIcons ? "" : "none" }} // update to mention to team
                    alt="profile pic"
                  ></img>
                </div>
              );
            })}
        </div>
        {/* ======================================================================== */}

        {/* ====== displaying side icons plus names ========================================================= */}
        {sideIcons.map((sideIcon, index) => (
          //mapping out the buttons

          <Link
            to={sideIcon.routes}
            key={index}
            className={styles.btn}
            style={{
              backgroundColor: selectIcons === index ? "#B2E4FA" : "",
            }}
            onClick={() => {
              setSelectIcons(index);
            }}
          >
            <div
              className={styles.img}
              style={{
                marginLeft: displayIcons ? "" : "12px",
                marginBottom: displayIcons ? "" : "8px",
                scale: displayIcons ? "" : "1.5", // ended up using scale to change icon size
              }}
            >
              {selectIcons === index ? sideIcon.iconSelected : sideIcon.icon}
            </div>
            <p
              className={styles.name}
              style={{
                display: displayIcons ? "" : "none",
                color: selectIcons === index ? "#6C6C6C" : "white",
              }}
            >
              {sideIcon.name}
            </p>
          </Link>
        ))}
        {/* ======================================================================== */}

        {/* ============arrow======================================================= */}
        <div
          className={styles.arrowOpen}
          style={{
            justifyContent: displayIcons ? "flex-end" : "flex-end",
            // it's flex-end for !displayIcons because it rotates 180
            transform: displayIcons ? "" : "Rotate(180deg)",

            marginLeft: displayIcons ? "150px" : "",
          }}
        >
          <img className={styles.arrow} src={arrowLeft} onClick={toggle} />
        </div>
        {/* ======================================================================== */}

        {/* ===== menu icons=============================================================== */}
        <div className={styles.menuNavBody}>
          <div
            className={styles.menuNav}
            style={{
              marginLeft: displayIcons ? "70px" : "18px",
              flexDirection: displayIcons ? "row" : "column",
              alignItems: displayIcons ? "flex end" : "",
            }}
          >
            <img src={profile} style={{ margin: "8px" }} />
            <img src={settings} style={{ margin: "8px" }} />
            <img src={signOut} style={{ margin: "8px" }} />
          </div>
        </div>
        {/* ======================================================================== */}
      </div>
    </div>
  );
}
export default SideBar;
