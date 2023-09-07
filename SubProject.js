import Screensub from "./Screensub.png"
import styles from "./SubProject.module.css"
import {MdInsertPhoto} from "react-icons/md"

export default function SubProject(){
    return(
        <div>
            <img className={styles.ScreenSub} src={Screensub} alt="ScreenSub"></img>
            <h3 className={styles.SubHeading}>Submit project photo</h3>
            <p className={styles.paraGraph1}>After completing your project, take a screenshot of your project and upload it here.</p>
            <a href=" " className={styles.sendPics}>
                <MdInsertPhoto className={styles.icon1} />
                <br></br>
                Send Photo
            </a>
            </div>
    )
}